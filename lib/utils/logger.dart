import 'package:flutter/foundation.dart';

class AppLogger {
  static const String _prefijo = '🛍️ TiendaApp';

  // Log de información general
  static void info(String mensaje, [String? contexto]) {
    if (kDebugMode) {
      final ctx = contexto != null ? '[$contexto]' : '';
      print('$_prefijo ℹ️ $ctx $mensaje');
    }
  }

  // Log de errores
  static void error(
    String mensaje, [
    dynamic error,
    StackTrace? stackTrace,
    String? contexto,
  ]) {
    if (kDebugMode) {
      final ctx = contexto != null ? '[$contexto]' : '';
      print('$_prefijo ❌ $ctx $mensaje');
      if (error != null) {
        print('   Error: $error');
      }
      if (stackTrace != null) {
        print('   Stack: $stackTrace');
      }
    }
  }

  // Log de advertencias
  static void warning(String mensaje, [String? contexto]) {
    if (kDebugMode) {
      final ctx = contexto != null ? '[$contexto]' : '';
      print('$_prefijo ⚠️ $ctx $mensaje');
    }
  }

  // Log de éxito
  static void success(String mensaje, [String? contexto]) {
    if (kDebugMode) {
      final ctx = contexto != null ? '[$contexto]' : '';
      print('$_prefijo ✅ $ctx $mensaje');
    }
  }

  // Log de requests HTTP
  static void httpRequest(
    String metodo,
    String url, [
    Map<String, dynamic>? datos,
  ]) {
    if (kDebugMode) {
      print('$_prefijo 🌐 $metodo $url');
      if (datos != null) {
        print('   Datos: $datos');
      }
    }
  }

  // Log de responses HTTP
  static void httpResponse(int statusCode, String url, [dynamic respuesta]) {
    if (kDebugMode) {
      final emoji = statusCode >= 200 && statusCode < 300 ? '✅' : '❌';
      print('$_prefijo 📡 $emoji $statusCode $url');
      if (respuesta != null) {
        print('   Respuesta: $respuesta');
      }
    }
  }

  // Log de navegación
  static void navigation(String pantalla, [String? accion]) {
    if (kDebugMode) {
      final acc = accion != null ? ' ($accion)' : '';
      print('$_prefijo 🧭 Navegando a: $pantalla$acc');
    }
  }

  // Log de estado del provider
  static void providerState(String provider, String estado, [dynamic datos]) {
    if (kDebugMode) {
      print('$_prefijo 🔄 [$provider] $estado');
      if (datos != null) {
        print('   Datos: $datos');
      }
    }
  }
}
