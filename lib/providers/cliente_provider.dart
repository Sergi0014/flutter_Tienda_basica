import 'package:flutter/material.dart';
import '../models/cliente.dart';
import '../services/cliente_service.dart';
import '../utils/exceptions.dart';

class ClienteProvider with ChangeNotifier {
  final ClienteService _clienteService = ClienteService();

  List<Cliente> _clientes = [];
  bool _cargando = false;
  String? _error;
  Cliente? _clienteSeleccionado;

  // Getters
  List<Cliente> get clientes => _clientes;
  bool get cargando => _cargando;
  String? get error => _error;
  Cliente? get clienteSeleccionado => _clienteSeleccionado;

  // Cargar todos los clientes
  Future<void> cargarClientes() async {
    _setCargando(true);
    _setError(null);

    try {
      _clientes = await _clienteService.obtenerClientes();
      notifyListeners();
    } catch (e) {
      _setError(_getErrorMessage(e));
    } finally {
      _setCargando(false);
    }
  }

  // Obtener cliente por ID
  Future<Cliente?> obtenerClientePorId(int id) async {
    try {
      final cliente = await _clienteService.obtenerClientePorId(id);
      _clienteSeleccionado = cliente;
      notifyListeners();
      return cliente;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return null;
    }
  }

  // Crear nuevo cliente
  Future<bool> crearCliente(Cliente cliente) async {
    _setCargando(true);
    _setError(null);

    try {
      // Validar email único
      final emailExiste = await _clienteService.emailExiste(cliente.email);
      if (emailExiste) {
        _setError('El email ya está registrado');
        _setCargando(false);
        return false;
      }

      final nuevoCliente = await _clienteService.crearCliente(cliente);
      _clientes.add(nuevoCliente);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setCargando(false);
    }
  }

  // Actualizar cliente existente
  Future<bool> actualizarCliente(int id, Cliente cliente) async {
    _setCargando(true);
    _setError(null);

    try {
      // Validar email único (excluyendo el cliente actual)
      final emailExiste = await _clienteService.emailExiste(
        cliente.email,
        clienteIdExcluir: id,
      );
      if (emailExiste) {
        _setError('El email ya está registrado');
        _setCargando(false);
        return false;
      }

      final clienteActualizado = await _clienteService.actualizarCliente(
        id,
        cliente,
      );
      final index = _clientes.indexWhere((c) => c.id == id);
      if (index != -1) {
        _clientes[index] = clienteActualizado;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setCargando(false);
    }
  }

  // Eliminar cliente
  Future<bool> eliminarCliente(int id) async {
    _setCargando(true);
    _setError(null);

    try {
      await _clienteService.eliminarCliente(id);
      _clientes.removeWhere((cliente) => cliente.id == id);
      if (_clienteSeleccionado?.id == id) {
        _clienteSeleccionado = null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setCargando(false);
    }
  }

  // Buscar clientes por nombre
  Future<List<Cliente>> buscarClientes(String termino) async {
    if (termino.isEmpty) return _clientes;

    try {
      return await _clienteService.buscarClientesPorNombre(termino);
    } catch (e) {
      _setError(_getErrorMessage(e));
      return [];
    }
  }

  // Seleccionar cliente
  void seleccionarCliente(Cliente? cliente) {
    _clienteSeleccionado = cliente;
    notifyListeners();
  }

  // Limpiar errores
  void limpiarError() {
    _error = null;
    notifyListeners();
  }

  // Métodos privados
  void _setCargando(bool valor) {
    _cargando = valor;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    if (error is ApiException) {
      return error.message;
    }
    return 'Error inesperado: $error';
  }

  @override
  void dispose() {
    _clienteService.dispose();
    super.dispose();
  }
}
