import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../services/producto_service.dart';
import '../utils/exceptions.dart';

class ProductoProvider with ChangeNotifier {
  final ProductoService _productoService = ProductoService();

  List<Producto> _productos = [];
  bool _cargando = false;
  String? _error;
  Producto? _productoSeleccionado;

  // Getters
  List<Producto> get productos => _productos;
  bool get cargando => _cargando;
  String? get error => _error;
  Producto? get productoSeleccionado => _productoSeleccionado;

  // Cargar todos los productos
  Future<void> cargarProductos() async {
    _setCargando(true);
    _setError(null);

    try {
      _productos = await _productoService.obtenerProductos();
      notifyListeners();
    } catch (e) {
      _setError(_getErrorMessage(e));
    } finally {
      _setCargando(false);
    }
  }

  // Obtener producto por ID
  Future<Producto?> obtenerProductoPorId(int id) async {
    try {
      final producto = await _productoService.obtenerProductoPorId(id);
      _productoSeleccionado = producto;
      notifyListeners();
      return producto;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return null;
    }
  }

  // Crear nuevo producto
  Future<bool> crearProducto(Producto producto) async {
    _setCargando(true);
    _setError(null);

    try {
      // Validar nombre único
      final nombreExiste = await _productoService.nombreExiste(producto.nombre);
      if (nombreExiste) {
        _setError('Ya existe un producto con este nombre');
        _setCargando(false);
        return false;
      }

      final nuevoProducto = await _productoService.crearProducto(producto);
      _productos.add(nuevoProducto);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setCargando(false);
    }
  }

  // Actualizar producto existente
  Future<bool> actualizarProducto(int id, Producto producto) async {
    _setCargando(true);
    _setError(null);

    try {
      // Validar nombre único (excluyendo el producto actual)
      final nombreExiste = await _productoService.nombreExiste(
        producto.nombre,
        productoIdExcluir: id,
      );
      if (nombreExiste) {
        _setError('Ya existe un producto con este nombre');
        _setCargando(false);
        return false;
      }

      final productoActualizado = await _productoService.actualizarProducto(
        id,
        producto,
      );
      final index = _productos.indexWhere((p) => p.id == id);
      if (index != -1) {
        _productos[index] = productoActualizado;
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

  // Eliminar producto
  Future<bool> eliminarProducto(int id) async {
    _setCargando(true);
    _setError(null);

    try {
      await _productoService.eliminarProducto(id);
      _productos.removeWhere((producto) => producto.id == id);
      if (_productoSeleccionado?.id == id) {
        _productoSeleccionado = null;
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

  // Buscar productos por nombre
  Future<List<Producto>> buscarProductos(String termino) async {
    if (termino.isEmpty) return _productos;

    try {
      return await _productoService.buscarProductosPorNombre(termino);
    } catch (e) {
      _setError(_getErrorMessage(e));
      return [];
    }
  }

  // Filtrar productos por rango de precio
  Future<List<Producto>> filtrarPorPrecio(double min, double max) async {
    try {
      return await _productoService.obtenerProductosPorRangoPrecio(min, max);
    } catch (e) {
      _setError(_getErrorMessage(e));
      return [];
    }
  }

  // Seleccionar producto
  void seleccionarProducto(Producto? producto) {
    _productoSeleccionado = producto;
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
    _productoService.dispose();
    super.dispose();
  }
}
