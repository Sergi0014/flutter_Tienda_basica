import 'package:flutter/material.dart';
import '../models/venta.dart';
import '../services/venta_service.dart';
import '../utils/exceptions.dart';
import '../utils/logger.dart';

class VentaProvider with ChangeNotifier {
  final VentaService _ventaService = VentaService();

  List<Venta> _ventas = [];
  bool _cargando = false;
  String? _error;
  Venta? _ventaSeleccionada;
  Map<String, dynamic>? _estadisticas;

  // Getters
  List<Venta> get ventas => _ventas;
  bool get cargando => _cargando;
  String? get error => _error;
  Venta? get ventaSeleccionada => _ventaSeleccionada;
  Map<String, dynamic>? get estadisticas => _estadisticas;

  // Cargar todas las ventas
  Future<void> cargarVentas() async {
    _setCargando(true);
    _setError(null);

    try {
      _ventas = await _ventaService.obtenerVentas();
      await _cargarEstadisticas();
      notifyListeners();
    } catch (e) {
      _setError(_getErrorMessage(e));
    } finally {
      _setCargando(false);
    }
  }

  // Obtener venta por ID
  Future<Venta?> obtenerVentaPorId(int id) async {
    try {
      final venta = await _ventaService.obtenerVentaPorId(id);
      _ventaSeleccionada = venta;
      notifyListeners();
      return venta;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return null;
    }
  }

  // Crear nueva venta
  Future<bool> crearVenta(Venta venta) async {
    _setCargando(true);
    _setError(null);

    try {
      // Validar datos antes de enviar
      if (!venta.isValid) {
        throw ValidationException(
          message: venta.validationMessage ?? 'Datos de venta inválidos',
        );
      }

      final nuevaVenta = await _ventaService.crearVenta(venta);
      _ventas.add(nuevaVenta);
      await _cargarEstadisticas();
      notifyListeners();
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setCargando(false);
    }
  }

  // Eliminar venta con feedback mejorado
  Future<Map<String, dynamic>> eliminarVentaConFeedback(int id) async {
    _setCargando(true);
    _setError(null);

    try {
      AppLogger.info('Iniciando eliminación de venta $id', 'VentaProvider');

      // Usar el nuevo método que devuelve información detallada
      final result = await _ventaService.eliminarVentaConFeedback(id);

      if (result['success']) {
        AppLogger.info(
          'Servicio completó eliminación exitosamente, actualizando lista local',
          'VentaProvider',
        );

        _ventas.removeWhere((venta) => venta.id == id);
        if (_ventaSeleccionada?.id == id) {
          _ventaSeleccionada = null;
        }

        _calcularEstadisticasLocal();
        notifyListeners();

        AppLogger.success(
          'Eliminación completada exitosamente',
          'VentaProvider',
        );
      } else {
        AppLogger.error(
          'Error en eliminación',
          result['message'],
          null,
          'VentaProvider',
        );
        _setError(result['message']);
      }

      return result;
    } catch (e) {
      AppLogger.error(
        'Error inesperado en eliminación',
        e,
        null,
        'VentaProvider',
      );
      final errorResult = {
        'success': false,
        'message': 'Error inesperado: $e',
        'errorType': 'unknown',
        'deletedId': id,
      };
      _setError(errorResult['message'] as String?);
      return errorResult;
    } finally {
      AppLogger.info('Finalizando proceso de eliminación', 'VentaProvider');
      _setCargando(false);
    }
  }

  // Método original mantenido para compatibilidad
  Future<bool> eliminarVenta(int id) async {
    final result = await eliminarVentaConFeedback(id);
    return result['success'] ?? false;
  }

  // Obtener ventas por cliente
  Future<List<Venta>> obtenerVentasPorCliente(int clienteId) async {
    try {
      return await _ventaService.obtenerVentasPorCliente(clienteId);
    } catch (e) {
      _setError(_getErrorMessage(e));
      return [];
    }
  }

  // Obtener ventas por producto
  Future<List<Venta>> obtenerVentasPorProducto(int productoId) async {
    try {
      return await _ventaService.obtenerVentasPorProducto(productoId);
    } catch (e) {
      _setError(_getErrorMessage(e));
      return [];
    }
  }

  // Seleccionar venta
  void seleccionarVenta(Venta? venta) {
    _ventaSeleccionada = venta;
    notifyListeners();
  }

  // Cargar estadísticas
  Future<void> _cargarEstadisticas() async {
    try {
      AppLogger.info('Iniciando carga de estadísticas', 'VentaProvider');
      _estadisticas = await _ventaService.obtenerEstadisticasVentas();
      AppLogger.info('Estadísticas cargadas exitosamente', 'VentaProvider');
    } catch (e) {
      AppLogger.warning('Error cargando estadísticas: $e', 'VentaProvider');
      // No mostrar error para estadísticas, solo log
      debugPrint('Error cargando estadísticas: $e');
    }
  }

  // Calcular total de ventas
  Future<double> calcularTotalVentas() async {
    try {
      return await _ventaService.calcularTotalVentas();
    } catch (e) {
      _setError(_getErrorMessage(e));
      return 0.0;
    }
  }

  // Limpiar errores
  void limpiarError() {
    _error = null;
    notifyListeners();
  }

  // Calcular estadísticas localmente
  void _calcularEstadisticasLocal() {
    if (_ventas.isEmpty) {
      _estadisticas = {
        'totalVentas': 0,
        'totalCantidad': 0,
        'totalMonto': 0.0,
        'promedioVenta': 0.0,
      };
      return;
    }

    final totalVentas = _ventas.length;
    final totalCantidad = _ventas.fold<int>(
      0,
      (sum, venta) => sum + venta.cantidad,
    );
    final totalMonto = _ventas.fold<double>(
      0.0,
      (sum, venta) => sum + venta.total,
    );
    final promedioVenta = totalMonto / totalVentas;

    _estadisticas = {
      'totalVentas': totalVentas,
      'totalCantidad': totalCantidad,
      'totalMonto': totalMonto,
      'promedioVenta': promedioVenta,
    };
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
      // Si el error contiene información específica sobre campos inválidos
      if (error.message.contains('should not exist')) {
        return 'Error de validación: El servidor no acepta algunos campos enviados';
      }
      return error.message;
    }
    if (error is ValidationException) {
      return error.message;
    }
    return 'Error inesperado: $error';
  }

  @override
  void dispose() {
    _ventaService.dispose();
    super.dispose();
  }
}
