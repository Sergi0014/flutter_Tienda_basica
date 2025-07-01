import '../config/api_config.dart';
import '../models/venta.dart';
import '../utils/exceptions.dart';
import '../utils/logger.dart';
import 'base_api_service.dart';

class VentaService extends BaseApiService {
  // Obtener todas las ventas
  Future<List<Venta>> obtenerVentas() async {
    try {
      final response = await get(ApiConfig.ventasEndpoint);

      if (response is List) {
        return response.map((json) {
          try {
            return Venta.fromJson(json as Map<String, dynamic>);
          } catch (e) {
            throw ApiException(message: 'Error al parsear venta: $e');
          }
        }).toList();
      }

      if (response == null) {
        return [];
      }

      throw ApiException(
        message: 'Respuesta inesperada del servidor al obtener ventas',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error al obtener ventas: $e');
    }
  }

  // Obtener venta por ID
  Future<Venta> obtenerVentaPorId(int id) async {
    try {
      if (id <= 0) {
        throw ValidationException(message: 'ID de venta inválido');
      }

      final response = await get('${ApiConfig.ventasEndpoint}/$id');

      if (response == null) {
        throw NotFoundException(message: 'Venta no encontrada');
      }

      return Venta.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error al obtener venta: $e');
    }
  }

  // Crear nueva venta
  Future<Venta> crearVenta(Venta venta) async {
    try {
      AppLogger.info('Creando venta', 'VentaService');

      // Validaciones antes de enviar
      if (venta.cantidad <= 0) {
        throw ValidationException(message: 'La cantidad debe ser mayor a 0');
      }

      if (venta.clienteId <= 0) {
        throw ValidationException(
          message: 'Debe seleccionar un cliente válido',
        );
      }

      if (venta.productoId <= 0) {
        throw ValidationException(
          message: 'Debe seleccionar un producto válido',
        );
      }

      // Preparar datos para envío - Solo campos que acepta el CreateVentaDto
      final ventaData = venta.toJsonForCreate();

      AppLogger.httpRequest('POST', ApiConfig.ventasEndpoint, ventaData);

      final response = await post(ApiConfig.ventasEndpoint, ventaData);

      if (response == null) {
        throw ServerException(
          message: 'El servidor no devolvió datos de la venta creada',
        );
      }

      AppLogger.success('Venta creada exitosamente', 'VentaService');
      return Venta.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error('Error al crear venta', e, null, 'VentaService');

      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error al crear venta: $e');
    }
  }

  // Actualizar venta existente
  Future<Venta> actualizarVenta(int id, Venta venta) async {
    try {
      AppLogger.info('Actualizando venta con ID: $id', 'VentaService');

      if (id <= 0) {
        throw ValidationException(message: 'ID de venta inválido');
      }

      // Validaciones
      if (venta.cantidad <= 0) {
        throw ValidationException(message: 'La cantidad debe ser mayor a 0');
      }

      if (venta.clienteId <= 0) {
        throw ValidationException(
          message: 'Debe seleccionar un cliente válido',
        );
      }

      if (venta.productoId <= 0) {
        throw ValidationException(
          message: 'Debe seleccionar un producto válido',
        );
      }

      // Solo enviar campos que acepta el UpdateVentaDto
      final datosActualizacion = venta.toJsonForUpdate();

      AppLogger.info(
        'Datos para actualización: $datosActualizacion',
        'VentaService',
      );
      AppLogger.httpRequest(
        'PUT',
        '${ApiConfig.ventasEndpoint}/$id',
        datosActualizacion,
      );

      final response = await put(
        '${ApiConfig.ventasEndpoint}/$id',
        datosActualizacion,
      );

      if (response == null) {
        throw ServerException(
          message: 'El servidor no devolvió datos de la venta actualizada',
        );
      }

      AppLogger.success('Venta actualizada exitosamente: $id', 'VentaService');
      return Venta.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error('Error al actualizar venta $id', e, null, 'VentaService');
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error al actualizar venta: $e');
    }
  }

  // Eliminar venta con manejo mejorado de errores
  Future<Map<String, dynamic>> eliminarVentaConFeedback(int id) async {
    try {
      if (id <= 0) {
        throw ValidationException(message: 'ID de venta inválido');
      }

      AppLogger.info('Eliminando venta con ID: $id', 'VentaService');
      AppLogger.httpRequest('DELETE', '${ApiConfig.ventasEndpoint}/$id');

      final response = await delete('${ApiConfig.ventasEndpoint}/$id');

      // Para DELETE, el backend puede devolver:
      // 1. status 204 con body vacío (response será null)
      // 2. status 200 con un objeto JSON
      String mensaje = 'Venta eliminada exitosamente';
      if (response != null && response is Map<String, dynamic>) {
        final success = response['success'] as bool? ?? true;
        final serverMessage = response['message'] as String?;

        if (!success) {
          throw ServerException(
            message: serverMessage ?? 'Error al eliminar venta',
          );
        }

        if (serverMessage != null && serverMessage.isNotEmpty) {
          mensaje = serverMessage;
        }

        AppLogger.info(
          'Respuesta del servidor: $serverMessage',
          'VentaService',
        );
      }

      AppLogger.success('Venta eliminada exitosamente: $id', 'VentaService');

      return {'success': true, 'message': mensaje, 'deletedId': id};
    } catch (e) {
      AppLogger.error('Error al eliminar venta $id', e, null, 'VentaService');

      // Retornar información detallada del error
      return {
        'success': false,
        'message': _getDetailedErrorMessage(e),
        'errorType': _getErrorType(e),
        'deletedId': id,
      };
    }
  }

  // Método original mantenido para compatibilidad
  Future<void> eliminarVenta(int id) async {
    final result = await eliminarVentaConFeedback(id);
    if (!result['success']) {
      // Recrear la excepción basada en el tipo de error
      final errorType = result['errorType'];
      final message = result['message'];

      switch (errorType) {
        case 'validation':
          throw ValidationException(message: message);
        case 'notFound':
          throw NotFoundException(message: message);
        case 'server':
          throw ServerException(message: message);
        case 'network':
          throw NetworkException(message: message);
        default:
          throw ApiException(message: message);
      }
    }
  }

  // Métodos auxiliares para manejo de errores
  String _getDetailedErrorMessage(dynamic error) {
    if (error is ValidationException) {
      return 'Dato inválido: ${error.message}';
    } else if (error is NotFoundException) {
      return 'Venta no encontrada: ${error.message}';
    } else if (error is ServerException) {
      return 'Error del servidor: ${error.message}';
    } else if (error is NetworkException) {
      return 'Error de conexión: ${error.message}';
    } else if (error is ApiException) {
      return 'Error de API: ${error.message}';
    } else {
      return 'Error inesperado: $error';
    }
  }

  String _getErrorType(dynamic error) {
    if (error is ValidationException) return 'validation';
    if (error is NotFoundException) return 'notFound';
    if (error is ServerException) return 'server';
    if (error is NetworkException) return 'network';
    if (error is ApiException) return 'api';
    return 'unknown';
  }

  // Obtener ventas por cliente
  Future<List<Venta>> obtenerVentasPorCliente(int clienteId) async {
    try {
      if (clienteId <= 0) {
        throw ValidationException(message: 'ID de cliente inválido');
      }

      final ventas = await obtenerVentas();
      return ventas.where((venta) => venta.clienteId == clienteId).toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error al obtener ventas por cliente: $e');
    }
  }

  // Obtener ventas por producto
  Future<List<Venta>> obtenerVentasPorProducto(int productoId) async {
    try {
      if (productoId <= 0) {
        throw ValidationException(message: 'ID de producto inválido');
      }

      final ventas = await obtenerVentas();
      return ventas.where((venta) => venta.productoId == productoId).toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error al obtener ventas por producto: $e');
    }
  }

  // Calcular total de ventas
  Future<double> calcularTotalVentas() async {
    try {
      final ventas = await obtenerVentas();
      return ventas.fold<double>(0.0, (total, venta) => total + venta.total);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error al calcular total de ventas: $e');
    }
  }

  // Obtener estadísticas de ventas
  Future<Map<String, dynamic>> obtenerEstadisticasVentas() async {
    try {
      final ventas = await obtenerVentas();

      if (ventas.isEmpty) {
        return {
          'totalVentas': 0,
          'totalCantidad': 0,
          'totalMonto': 0.0,
          'promedioVenta': 0.0,
        };
      }

      final totalVentas = ventas.length;
      final totalCantidad = ventas.fold<int>(
        0,
        (sum, venta) => sum + venta.cantidad,
      );
      final totalMonto = ventas.fold<double>(
        0.0,
        (sum, venta) => sum + venta.total,
      );
      final promedioVenta = totalMonto / totalVentas;

      return {
        'totalVentas': totalVentas,
        'totalCantidad': totalCantidad,
        'totalMonto': totalMonto,
        'promedioVenta': promedioVenta,
      };
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error al obtener estadísticas: $e');
    }
  }

  // Validar existencia de cliente y producto antes de crear venta
  Future<bool> validarDatosVenta(int clienteId, int productoId) async {
    try {
      // Esta validación debería ser implementada consultando
      // los servicios de cliente y producto, pero por simplicidad
      // solo validamos que los IDs sean válidos
      if (clienteId <= 0 || productoId <= 0) {
        return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
