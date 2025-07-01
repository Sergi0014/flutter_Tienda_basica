class ApiConfig {
  // URL base del backend NestJS desplegado en Render
  static const String _productionUrl =
      'https://tienda-nestjs-backend.onrender.com';

  // URLs para desarrollo local
  // ignore: unused_field
  static const String _emulatorUrl = 'http://10.0.2.2:3000';
  // ignore: unused_field
  static const String _localhostUrl = 'http://localhost:3000';
  // ignore: unused_field
  static const String _deviceUrl = 'ip de tu pc:3000';

  // Configuración activa - USAR PRODUCCIÓN PARA ANDROID RELEASE
  static const String baseUrl = _productionUrl; // ✅ USAR PARA DEPLOYMENT
  // static const String baseUrl = _emulatorUrl; // Para emulador Android desarrollo
  // static const String baseUrl = _localhostUrl; // Para desarrollo local
  // static const String baseUrl = _deviceUrl; // Para dispositivo físico desarrollo

  // Detectar si estamos en modo debug o release
  static bool get isProduction => baseUrl == _productionUrl;

  // Endpoints de la API
  static const String clientesEndpoint = '/client';
  static const String productosEndpoint = '/product';
  static const String ventasEndpoint = '/venta';

  // Headers por defecto - mejorados para producción
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (isProduction) 'User-Agent': 'TiendaFlutter/1.0.0',
  };

  // Timeouts ajustados para producción
  static Duration get connectionTimeout =>
      isProduction ? const Duration(seconds: 30) : const Duration(seconds: 10);

  static Duration get receiveTimeout =>
      isProduction ? const Duration(seconds: 30) : const Duration(seconds: 10);
}
