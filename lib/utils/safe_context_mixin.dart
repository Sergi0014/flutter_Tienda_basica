import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Mixin para manejar de forma segura el contexto en widgets con estado
/// que realizan operaciones asíncronas
mixin SafeContextMixin<T extends StatefulWidget> on State<T> {
  // Referencia al contexto capturada de forma segura
  BuildContext? _safeContext;

  // Referencias seguras a los servicios
  ScaffoldMessengerState? _scaffoldMessenger;
  NavigatorState? _navigator;
  bool _isDisposed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDisposed) {
      _safeContext = context;

      // Capturar referencias seguras una sola vez
      try {
        _scaffoldMessenger = ScaffoldMessenger.of(context);
        _navigator = Navigator.of(context);
      } catch (e) {
        debugPrint('Error capturando referencias: $e');
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _safeContext = null;
    _scaffoldMessenger = null;
    _navigator = null;
    super.dispose();
  }

  /// Verifica si el widget está disponible para operaciones
  bool get isWidgetSafe => mounted && !_isDisposed && _safeContext != null;

  /// Obtiene el contexto de forma segura
  BuildContext? get safeContext => isWidgetSafe ? _safeContext : null;

  /// Ejecuta una función solo si el widget sigue montado
  void executeIfMounted(VoidCallback callback) {
    if (isWidgetSafe) {
      try {
        callback();
      } catch (e) {
        debugPrint('Error en executeIfMounted: $e');
      }
    } else {
      _logSafetyViolation('executeIfMounted');
    }
  }

  /// Ejecuta una función asíncrona solo si el widget sigue montado
  Future<void> executeAsyncIfMounted(Future<void> Function() callback) async {
    if (isWidgetSafe) {
      try {
        await callback();
      } catch (e) {
        debugPrint('Error en executeAsyncIfMounted: $e');
      }
    }
  }

  /// Ejecuta una función asíncrona de forma segura con retraso
  Future<void> executeAsyncAfterDelay(
    Future<void> Function() callback, {
    Duration delay = const Duration(milliseconds: 150),
  }) async {
    await Future.delayed(delay);
    if (isWidgetSafe) {
      try {
        await callback();
      } catch (e) {
        debugPrint('Error en executeAsyncAfterDelay: $e');
      }
    }
  }

  /// Muestra un SnackBar de forma segura usando referencia capturada
  void showSnackBarSafely(SnackBar snackBar) {
    // Intentar usar el ScaffoldMessenger capturado si el widget está montado
    if (_scaffoldMessenger != null && isWidgetSafe) {
      try {
        _scaffoldMessenger!.showSnackBar(snackBar);
        return;
      } catch (e) {
        debugPrint('Error mostrando SnackBar con scaffoldMessenger: $e');
      }
    }
    // Fallback: usar el ScaffoldMessenger del contexto principal del Navigator
    try {
      final navigatorContext = _navigator?.context;
      if (navigatorContext != null) {
        ScaffoldMessenger.of(navigatorContext).showSnackBar(snackBar);
      }
    } catch (e) {
      debugPrint('Error mostrando SnackBar fallback: $e');
    }
  }

  /// Muestra un SnackBar de éxito
  void showSuccessSnackBar(String message) {
    showSnackBarSafely(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Muestra un SnackBar de error
  void showErrorSnackBar(String message) {
    showSnackBarSafely(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Navega de forma segura usando referencia capturada
  void navigateSafely(Widget destination) {
    if (isWidgetSafe && _navigator != null) {
      try {
        _navigator!.push(MaterialPageRoute(builder: (context) => destination));
      } catch (e) {
        debugPrint('Error navegando: $e');
      }
    }
  }

  /// Navega de forma segura y ejecuta callback al regresar
  Future<void> navigateAndCallback(
    Widget destination,
    VoidCallback? onReturn,
  ) async {
    if (isWidgetSafe && _navigator != null) {
      try {
        await _navigator!.push(
          MaterialPageRoute(builder: (context) => destination),
        );

        if (onReturn != null && isWidgetSafe) {
          executeIfMounted(onReturn);
        }
      } catch (e) {
        debugPrint('Error en navigateAndCallback: $e');
      }
    }
  }

  /// Obtiene un provider de forma segura
  P? getProviderSafely<P>() {
    final context = safeContext;
    if (context != null) {
      try {
        return context.read<P>();
      } catch (e) {
        debugPrint('Error al obtener provider $P: $e');
        return null;
      }
    }
    return null;
  }

  /// Ejecuta una operación del provider de forma segura
  Future<void> executeProviderOperation<P>(
    Future<bool> Function(P provider) operation,
    String successMessage,
    String errorMessagePrefix,
  ) async {
    // Verificar que el widget sigue disponible antes de comenzar
    if (!isWidgetSafe) return;

    final provider = getProviderSafely<P>();
    if (provider == null) return;

    try {
      final success = await operation(provider);

      // Verificar nuevamente que el widget sigue disponible después de la operación
      if (isWidgetSafe) {
        if (success) {
          showSuccessSnackBar(successMessage);
        } else {
          // Intentar obtener mensaje de error del provider si tiene la propiedad
          String errorMessage = errorMessagePrefix;
          try {
            final dynamic providerDynamic = provider;
            if (providerDynamic.error != null) {
              errorMessage = providerDynamic.error;
            }
          } catch (e) {
            // Si no tiene propiedad error, usar mensaje por defecto
          }
          showErrorSnackBar(errorMessage);
        }
      }
    } catch (e) {
      // Verificar que el widget sigue disponible antes de mostrar error
      if (isWidgetSafe) {
        showErrorSnackBar('$errorMessagePrefix: $e');
      }
    }
  }

  /// Muestra un diálogo de confirmación de forma segura
  Future<bool> showConfirmationDialogSafely({
    required String title,
    required String content,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    Color? confirmColor,
  }) async {
    // Intentar usar el contexto seguro o el contexto del Navigator como fallback
    final BuildContext? dialogContext = safeContext ?? _navigator?.context;
    if (dialogContext == null) return false;

    try {
      final result = await showDialog<bool>(
        context: dialogContext,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(cancelText),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: confirmColor != null
                  ? ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      foregroundColor: Colors.white,
                    )
                  : null,
              child: Text(confirmText),
            ),
          ],
        ),
      );

      return result ?? false;
    } catch (e) {
      debugPrint('Error en showConfirmationDialogSafely: $e');
      return false;
    }
  }

  /// Muestra un bottom sheet de forma segura
  Future<T?> showBottomSheetSafely<T>(Widget bottomSheet) async {
    final context = safeContext;
    if (context == null) return null;

    try {
      return await showModalBottomSheet<T>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        isScrollControlled: true,
        builder: (bottomSheetContext) => bottomSheet,
      );
    } catch (e) {
      debugPrint('Error en showBottomSheetSafely: $e');
      return null;
    }
  }

  /// Cierra navegación de forma segura
  void popSafely<T>([T? result]) {
    if (isWidgetSafe && _navigator != null && _navigator!.canPop()) {
      try {
        _navigator!.pop(result);
      } catch (e) {
        debugPrint('Error en popSafely: $e');
      }
    }
  }

  /// Ejecuta una operación después de cerrar navegación
  void executeAfterPop(VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      executeIfMounted(callback);
    });
  }

  /// Registra intentos de uso después del dispose para debugging
  void _logSafetyViolation(String operation) {
    debugPrint(
      '⚠️ SafeContextMixin: Intento de $operation después de dispose/unmount',
    );
  }
}
