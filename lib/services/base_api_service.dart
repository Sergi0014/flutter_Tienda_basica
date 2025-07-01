import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/exceptions.dart';

class BaseApiService {
  final http.Client _client = http.Client();

  // Realizar petición GET
  Future<dynamic> get(String endpoint) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      print('DEBUG API - GET request to: $uri');
      print('DEBUG API - Timeout: ${ApiConfig.connectionTimeout}');

      final response = await _client
          .get(uri, headers: ApiConfig.headers)
          .timeout(ApiConfig.connectionTimeout);

      print('DEBUG API - GET response received: ${response.statusCode}');
      return _handleResponse(response);
    } on TimeoutException catch (e) {
      print('DEBUG API - TimeoutException in GET: $e');
      throw NetworkException(
        message:
            'Timeout: No se pudo conectar al servidor en ${ApiConfig.baseUrl}. Verifica la configuración de IP.',
      );
    } on SocketException catch (e) {
      print('DEBUG API - SocketException in GET: $e');
      throw NetworkException(
        message: 'Error de conexión. Verifica tu conexión a internet.',
      );
    } catch (e) {
      print('DEBUG API - Error in GET: $e');
      throw ApiException(message: 'Error inesperado: $e');
    }
  }

  // Realizar petición POST
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      print('DEBUG API - POST $uri');
      print('DEBUG API - Data: ${json.encode(data)}');

      final response = await _client
          .post(uri, headers: ApiConfig.headers, body: json.encode(data))
          .timeout(ApiConfig.connectionTimeout);

      print('DEBUG API - Response status: ${response.statusCode}');
      print('DEBUG API - Response body: ${response.body}');

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException(
        message: 'Error de conexión. Verifica tu conexión a internet.',
      );
    } catch (e) {
      print('DEBUG API - Error en POST: $e');
      throw ApiException(message: 'Error inesperado: $e');
    }
  }

  // Realizar petición PUT
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      print('DEBUG API - PUT $uri');
      print('DEBUG API - PUT Data: ${json.encode(data)}');
      print('DEBUG API - PUT Headers: ${ApiConfig.headers}');

      final response = await _client
          .put(uri, headers: ApiConfig.headers, body: json.encode(data))
          .timeout(ApiConfig.connectionTimeout);

      print('DEBUG API - PUT Response status: ${response.statusCode}');
      print('DEBUG API - PUT Response body: ${response.body}');

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException(
        message: 'Error de conexión. Verifica tu conexión a internet.',
      );
    } catch (e) {
      print('DEBUG API - Error en PUT: $e');
      throw ApiException(message: 'Error inesperado en PUT: $e');
    }
  }

  // Realizar petición DELETE
  Future<dynamic> delete(String endpoint) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      print('🔥 DEBUG DELETE - URI: $uri');

      final response = await _client
          .delete(uri, headers: ApiConfig.headers)
          .timeout(ApiConfig.connectionTimeout);

      print('🔥 DEBUG DELETE - Status: ${response.statusCode}');
      print('🔥 DEBUG DELETE - Headers: ${response.headers}');
      print('🔥 DEBUG DELETE - Body: "${response.body}"');
      print('🔥 DEBUG DELETE - Body length: ${response.body.length}');

      return _handleResponse(response);
    } on TimeoutException catch (e) {
      print('🔥 DEBUG DELETE - TimeoutException: $e');
      throw NetworkException(
        message: 'Timeout en DELETE: No se pudo conectar al servidor.',
      );
    } on SocketException catch (e) {
      print('🔥 DEBUG DELETE - SocketException: $e');
      throw NetworkException(
        message:
            'Error de conexión en DELETE. Verifica tu conexión a internet.',
      );
    } catch (e) {
      print('🔥 DEBUG DELETE - Exception: $e');
      throw ApiException(message: 'Error inesperado en DELETE: $e');
    }
  }

  // Manejar respuestas HTTP
  dynamic _handleResponse(http.Response response) {
    print('🔥 DEBUG RESPONSE - Status: ${response.statusCode}');
    print('🔥 DEBUG RESPONSE - Body: "${response.body}"');

    switch (response.statusCode) {
      case 200:
      case 201:
        if (response.body.isEmpty) {
          print('🔥 DEBUG RESPONSE - Empty body for 20x response');
          return null;
        }
        try {
          final decoded = json.decode(response.body);
          print('🔥 DEBUG RESPONSE - Success decoded: $decoded');
          return decoded;
        } catch (e) {
          print('🔥 DEBUG RESPONSE - Error decoding: $e');
          throw ApiException(
            message: 'Error al procesar respuesta del servidor',
          );
        }
      case 204: // No Content - típico para DELETE exitoso
        print('🔥 DEBUG RESPONSE - 204 No Content (DELETE exitoso)');
        return null; // Exitoso pero sin contenido
      case 400:
        final errorMsg = _getErrorMessage(response.body, 'Datos inválidos');
        print('DEBUG API - Validation error (400): $errorMsg');
        print('DEBUG API - Full 400 response body: ${response.body}');

        // Intentar extraer detalles específicos de validación
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map<String, dynamic>) {
            if (errorData.containsKey('message')) {
              final message = errorData['message'];
              if (message is List) {
                final detailedErrors = message.join(', ');
                throw ValidationException(
                  message: 'Errores de validación: $detailedErrors',
                );
              } else if (message is String) {
                throw ValidationException(message: message);
              }
            }
          }
        } catch (e) {
          print('DEBUG API - Error parsing 400 response: $e');
        }

        throw ValidationException(message: errorMsg);
      case 401:
        throw ApiException(message: 'No autorizado', statusCode: 401);
      case 404:
        throw NotFoundException(
          message: _getErrorMessage(response.body, 'Recurso no encontrado'),
        );
      case 500:
        final errorMsg = _getErrorMessage(
          response.body,
          'Error interno del servidor',
        );
        print('DEBUG API - Server error: $errorMsg');
        print('DEBUG API - Full response body: ${response.body}');
        throw ServerException(message: errorMsg, statusCode: 500);
      default:
        print('DEBUG API - Unexpected status: ${response.statusCode}');
        print('DEBUG API - Response body: ${response.body}');
        throw ApiException(
          message: 'Error HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
    }
  }

  // Extraer mensaje de error del response body
  String _getErrorMessage(String responseBody, String defaultMessage) {
    try {
      final data = json.decode(responseBody);
      print('DEBUG API - Error response data: $data');

      // Intentar diferentes campos comunes para mensajes de error
      if (data is Map<String, dynamic>) {
        return data['message'] ??
            data['error'] ??
            data['detail'] ??
            data['msg'] ??
            '$defaultMessage (${data.toString()})';
      }

      return '$defaultMessage (${data.toString()})';
    } catch (e) {
      print('DEBUG API - Error parsing error message: $e');
      return '$defaultMessage (Raw: $responseBody)';
    }
  }

  // Limpiar recursos
  void dispose() {
    _client.close();
  }
}
