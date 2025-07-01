import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'providers/cliente_provider.dart';
import 'providers/producto_provider.dart';
import 'providers/venta_provider.dart';
import 'screens/home_screen.dart';
import 'utils/logger.dart';

void main() {
  // Configurar manejo de errores globales
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    AppLogger.error(
      'Error de Flutter capturado',
      details.exception,
      details.stack,
      'FlutterError',
    );
  };

  AppLogger.info('Iniciando aplicación Tienda Flutter', 'Main');
  runApp(const TiendaApp());
}

class TiendaApp extends StatelessWidget {
  const TiendaApp({super.key});

  @override
  Widget build(BuildContext context) {
    AppLogger.info('Construyendo aplicación principal', 'TiendaApp');

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ClienteProvider()),
        ChangeNotifierProvider(create: (_) => ProductoProvider()),
        ChangeNotifierProvider(create: (_) => VentaProvider()),
      ],
      child: MaterialApp(
        title: 'Tienda Flutter',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
        // Builder para capturar errores de navegación
        builder: (context, child) {
          return Builder(
            builder: (context) {
              // Configurar ErrorWidget personalizado
              ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
                if (kDebugMode) {
                  print('🚨 Error Widget: ${errorDetails.exception}');
                  return ErrorWidget(errorDetails.exception);
                }
                return const Material(
                  child: Center(
                    child: Text(
                      'Ha ocurrido un error\n🔧 Revisa los logs',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                );
              };
              return child ?? const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}
