import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../models/producto.dart';
import '../../providers/producto_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart' as widgets;
import '../../widgets/empty_state_widget.dart';
import '../../widgets/custom_card.dart';
import '../../utils/formatters.dart';
import '../../utils/safe_context_mixin.dart';
import 'producto_form_screen.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen>
    with SafeContextMixin {
  final TextEditingController _buscarController = TextEditingController();
  List<Producto> _productosFiltrados = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      executeIfMounted(() {
        final provider = getProviderSafely<ProductoProvider>();
        provider?.cargarProductos();
      });
    });
  }

  @override
  void dispose() {
    _buscarController.dispose();
    super.dispose();
  }

  void _filtrarProductos(String termino) {
    final provider = getProviderSafely<ProductoProvider>();
    if (provider == null) return;

    if (termino.isEmpty) {
      setState(() {
        _productosFiltrados = provider.productos;
      });
    } else {
      setState(() {
        _productosFiltrados = provider.productos
            .where(
              (producto) =>
                  producto.nombre.toLowerCase().contains(termino.toLowerCase()),
            )
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final provider = getProviderSafely<ProductoProvider>();
              provider?.cargarProductos().then((_) {
                // Actualizar la lista filtrada después de recargar
                _filtrarProductos(_buscarController.text);
              });
            },
          ),
        ],
      ),
      body: Consumer<ProductoProvider>(
        builder: (context, provider, child) {
          if (provider.cargando && provider.productos.isEmpty) {
            return const LoadingWidget(mensaje: 'Cargando productos...');
          }

          if (provider.error != null && provider.productos.isEmpty) {
            return widgets.ErrorWidget(
              mensaje: provider.error!,
              onReintentar: () => provider.cargarProductos(),
            );
          }

          // Inicializar filtros si es necesario
          if (_productosFiltrados.isEmpty && provider.productos.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _productosFiltrados = provider.productos;
              });
            });
          }

          // Actualizar filtros cuando cambie la lista de productos
          if (provider.productos.length != _productosFiltrados.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _filtrarProductos(_buscarController.text);
            });
          }

          return Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: _productosFiltrados.isEmpty
                    ? EmptyStateWidget(
                        titulo: 'No hay productos',
                        mensaje: 'Agrega tu primer producto para comenzar',
                        icono: Icons.inventory_2_outlined,
                        textoBoton: 'Agregar Producto',
                        onPressed: () => _navegarAFormulario(),
                      )
                    : _buildProductosList(),
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _buscarController,
        decoration: InputDecoration(
          hintText: 'Buscar productos...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _buscarController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _buscarController.clear();
                    _filtrarProductos('');
                  },
                )
              : null,
        ),
        onChanged: _filtrarProductos,
      ),
    );
  }

  Widget _buildProductosList() {
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: _productosFiltrados.length,
        itemBuilder: (context, index) {
          final producto = _productosFiltrados[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(child: _buildProductoCard(producto)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductoCard(Producto producto) {
    return CustomCard(
      onTap: () => _mostrarOpcionesProducto(producto),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.inventory_2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Formatters.capitalize(producto.nombre),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.formatPrice(producto.precio),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  void _mostrarOpcionesProducto(Producto producto) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                _navegarAFormulario(producto: producto);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmarEliminacion(producto);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _navegarAFormulario({Producto? producto}) async {
    final provider = getProviderSafely<ProductoProvider>();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductoFormScreen(
          producto: producto,
          onProductoSaved: () {
            // Actualización inmediata al guardar
            provider?.cargarProductos();
          },
        ),
      ),
    );

    // Actualización adicional al regresar por si el callback no funcionó
    if (result == true && provider != null) {
      await provider.cargarProductos();
      _filtrarProductos(_buscarController.text);
    }
  }

  void _confirmarEliminacion(Producto producto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de que deseas eliminar ${producto.nombre}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Ejecutar la eliminación de forma segura después de cerrar el diálogo
              await executeAsyncAfterDelay(() async {
                await executeProviderOperation<ProductoProvider>(
                  (provider) => provider.eliminarProducto(producto.id!),
                  'Producto eliminado exitosamente',
                  'Error al eliminar producto',
                );
                _filtrarProductos(_buscarController.text);
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
}
