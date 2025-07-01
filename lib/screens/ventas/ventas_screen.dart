import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../models/venta.dart';
import '../../providers/venta_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart' as widgets;
import '../../widgets/empty_state_widget.dart';
import '../../widgets/custom_card.dart';
import '../../utils/formatters.dart';
import '../../utils/safe_context_mixin.dart';
import 'venta_form_screen.dart';

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> with SafeContextMixin {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      executeIfMounted(() {
        final provider = getProviderSafely<VentaProvider>();
        provider?.cargarVentas();
      });
    });
  }

  @override
  void dispose() {
    // Limpiar cualquier referencia antes de destruir el widget
    // No realizar operaciones que requieran contexto aquí
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _mostrarDebugInfo,
            tooltip: 'Debug Info',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final provider = getProviderSafely<VentaProvider>();
              provider?.cargarVentas();
            },
          ),
        ],
      ),
      body: Consumer<VentaProvider>(
        builder: (context, provider, child) {
          if (provider.cargando && provider.ventas.isEmpty) {
            return const LoadingWidget(mensaje: 'Cargando ventas...');
          }

          if (provider.error != null && provider.ventas.isEmpty) {
            return widgets.ErrorWidget(
              mensaje: provider.error!,
              onReintentar: () => provider.cargarVentas(),
            );
          }

          return Column(
            children: [
              // Mensaje informativo de solo lectura
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Toca cualquier venta para eliminarla. No se pueden editar ventas existentes.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (provider.estadisticas != null)
                _buildEstadisticas(provider.estadisticas!),
              Expanded(
                child: provider.ventas.isEmpty
                    ? EmptyStateWidget(
                        titulo: 'No hay ventas',
                        mensaje: 'Registra tu primera venta para comenzar',
                        icono: Icons.point_of_sale_outlined,
                        textoBoton: 'Nueva Venta',
                        onPressed: () => _navegarAFormulario(),
                      )
                    : _buildVentasList(provider.ventas),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navegarAFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEstadisticas(Map<String, dynamic> estadisticas) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen de Ventas',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildEstadisticaItem(
                    'Total Ventas',
                    estadisticas['totalVentas'].toString(),
                    Icons.receipt_long,
                  ),
                ),
                Expanded(
                  child: _buildEstadisticaItem(
                    'Cantidad',
                    Formatters.formatNumber(estadisticas['totalCantidad']),
                    Icons.inventory,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildEstadisticaItem(
                    'Total Ingresos',
                    Formatters.formatPrice(estadisticas['totalMonto']),
                    Icons.attach_money,
                  ),
                ),
                Expanded(
                  child: _buildEstadisticaItem(
                    'Promedio',
                    Formatters.formatPrice(estadisticas['promedioVenta']),
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadisticaItem(String titulo, String valor, IconData icono) {
    return Column(
      children: [
        Icon(icono, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          titulo,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildVentasList(List<Venta> ventas) {
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
        itemCount: ventas.length,
        itemBuilder: (context, index) {
          final venta = ventas[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(child: _buildVentaCard(venta)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVentaCard(Venta venta) {
    return CustomCard(
      onTap: () => _confirmarEliminacion(venta),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.point_of_sale,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Venta #${venta.id}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      Formatters.formatPrice(venta.total),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Icono de eliminar
              Icon(
                Icons.delete_outline,
                size: 20,
                color: Colors.red.withOpacity(0.7),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.person,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cliente: ${venta.cliente?.nombre ?? 'ID: ${venta.clienteId}'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.inventory_2,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Producto: ${venta.producto?.nombre ?? 'ID: ${venta.productoId}'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.shopping_cart,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              Text(
                'Cantidad: ${Formatters.formatNumber(venta.cantidad)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navegarAFormulario() async {
    final provider = getProviderSafely<VentaProvider>();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VentaFormScreen(
          onVentaSaved: () {
            // Actualización inmediata al guardar
            provider?.cargarVentas();
          },
        ),
      ),
    );

    // Actualización adicional al regresar por si el callback no funcionó
    if (result == true && provider != null) {
      provider.cargarVentas();
    }
  }

  void _confirmarEliminacion(Venta venta) {
    final context = safeContext;
    if (context == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de que deseas eliminar la Venta #${venta.id}?\n\n'
          'Cliente: ${venta.cliente?.nombre ?? 'ID: ${venta.clienteId}'}\n'
          'Producto: ${venta.producto?.nombre ?? 'ID: ${venta.productoId}'}\n'
          'Total: ${Formatters.formatPrice(venta.total)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              // Ejecutar la eliminación con feedback mejorado
              await executeAsyncAfterDelay(() async {
                final provider = getProviderSafely<VentaProvider>();
                if (provider == null) return;

                final result = await provider.eliminarVentaConFeedback(
                  venta.id!,
                );

                final currentContext = safeContext;
                if (currentContext == null) return;

                if (result['success']) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Venta #${venta.id} eliminada exitosamente',
                      ),
                      backgroundColor: Colors.green,
                      action: SnackBarAction(
                        label: 'Ver detalles',
                        onPressed: () {
                          ScaffoldMessenger.of(currentContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                result['message'] ?? 'Eliminación exitosa',
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        result['message'] ?? 'Error al eliminar venta',
                      ),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDebugInfo() {
    final provider = getProviderSafely<VentaProvider>();
    if (provider == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Info - Ventas'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total ventas: ${provider.ventas.length}'),
              Text('Cargando: ${provider.cargando}'),
              Text('Error: ${provider.error ?? 'Ninguno'}'),
              const SizedBox(height: 16),
              const Text(
                'Ventas:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              for (final venta in provider.ventas.take(5))
                Text('- Venta #${venta.id}: \$${venta.total}'),
              if (provider.ventas.length > 5)
                Text('... y ${provider.ventas.length - 5} más'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
