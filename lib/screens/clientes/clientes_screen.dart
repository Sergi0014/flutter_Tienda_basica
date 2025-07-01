import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../models/cliente.dart';
import '../../providers/cliente_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart' as widgets;
import '../../widgets/empty_state_widget.dart';
import '../../widgets/custom_card.dart';
import '../../utils/formatters.dart';
import '../../utils/safe_context_mixin.dart';
import 'cliente_form_screen.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> with SafeContextMixin {
  final TextEditingController _buscarController = TextEditingController();
  List<Cliente> _clientesFiltrados = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      executeIfMounted(() {
        final provider = getProviderSafely<ClienteProvider>();
        provider?.cargarClientes();
      });
    });
  }

  @override
  void dispose() {
    _buscarController.dispose();
    super.dispose();
  }

  void _filtrarClientes(String termino) {
    final provider = getProviderSafely<ClienteProvider>();
    if (provider == null) return;

    if (termino.isEmpty) {
      setState(() {
        _clientesFiltrados = provider.clientes;
      });
    } else {
      setState(() {
        _clientesFiltrados = provider.clientes
            .where(
              (cliente) =>
                  cliente.nombre.toLowerCase().contains(
                    termino.toLowerCase(),
                  ) ||
                  cliente.email.toLowerCase().contains(termino.toLowerCase()),
            )
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final provider = getProviderSafely<ClienteProvider>();
              provider?.cargarClientes();
            },
          ),
        ],
      ),
      body: Consumer<ClienteProvider>(
        builder: (context, provider, child) {
          if (provider.cargando && provider.clientes.isEmpty) {
            return const LoadingWidget(mensaje: 'Cargando clientes...');
          }

          if (provider.error != null && provider.clientes.isEmpty) {
            return widgets.ErrorWidget(
              mensaje: provider.error!,
              onReintentar: () => provider.cargarClientes(),
            );
          }

          // Inicializar filtros si es necesario
          if (_clientesFiltrados.isEmpty && provider.clientes.isNotEmpty) {
            _clientesFiltrados = provider.clientes;
          }

          return Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: _clientesFiltrados.isEmpty
                    ? EmptyStateWidget(
                        titulo: 'No hay clientes',
                        mensaje: 'Agrega tu primer cliente para comenzar',
                        icono: Icons.people_outline,
                        textoBoton: 'Agregar Cliente',
                        onPressed: () => _navegarAFormulario(),
                      )
                    : _buildClientesList(),
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
          hintText: 'Buscar clientes...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _buscarController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _buscarController.clear();
                    _filtrarClientes('');
                  },
                )
              : null,
        ),
        onChanged: _filtrarClientes,
      ),
    );
  }

  Widget _buildClientesList() {
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: _clientesFiltrados.length,
        itemBuilder: (context, index) {
          final cliente = _clientesFiltrados[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(child: _buildClienteCard(cliente)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildClienteCard(Cliente cliente) {
    return CustomCard(
      onTap: () => _mostrarOpcionesCliente(cliente),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              cliente.nombre.isNotEmpty ? cliente.nombre[0].toUpperCase() : 'C',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Formatters.capitalize(cliente.nombre),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  cliente.email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
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

  void _mostrarOpcionesCliente(Cliente cliente) {
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
                _navegarAFormulario(cliente: cliente);
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
                _confirmarEliminacion(cliente);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _navegarAFormulario({Cliente? cliente}) async {
    final provider = getProviderSafely<ClienteProvider>();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClienteFormScreen(
          cliente: cliente,
          onClienteSaved: () {
            // Actualización inmediata al guardar
            provider?.cargarClientes();
          },
        ),
      ),
    );

    // Actualización adicional al regresar por si el callback no funcionó
    if (result == true && provider != null) {
      provider.cargarClientes();
      _filtrarClientes(_buscarController.text);
    }
  }

  void _confirmarEliminacion(Cliente cliente) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de que deseas eliminar a ${cliente.nombre}?',
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
                await executeProviderOperation<ClienteProvider>(
                  (provider) => provider.eliminarCliente(cliente.id!),
                  'Cliente eliminado exitosamente',
                  'Error al eliminar cliente',
                );
                _filtrarClientes(_buscarController.text);
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
