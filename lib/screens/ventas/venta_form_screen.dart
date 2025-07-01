import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/venta.dart';
import '../../models/cliente.dart';
import '../../models/producto.dart';
import '../../providers/venta_provider.dart';
import '../../providers/cliente_provider.dart';
import '../../providers/producto_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/loading_widget.dart';

class VentaFormScreen extends StatefulWidget {
  final VoidCallback? onVentaSaved;

  const VentaFormScreen({super.key, this.onVentaSaved});

  @override
  State<VentaFormScreen> createState() => _VentaFormScreenState();
}

class _VentaFormScreenState extends State<VentaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadController = TextEditingController();

  Cliente? _clienteSeleccionado;
  Producto? _productoSeleccionado;
  bool _cargando = false;
  double _total = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos();
    });

    _cantidadController.addListener(_calcularTotal);
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    final clienteProvider = context.read<ClienteProvider>();
    final productoProvider = context.read<ProductoProvider>();

    await Future.wait([
      clienteProvider.cargarClientes(),
      productoProvider.cargarProductos(),
    ]);

    // Debug: Verificar datos cargados
    print('DEBUG - Clientes cargados: ${clienteProvider.clientes.length}');
    for (final cliente in clienteProvider.clientes) {
      print('  Cliente: ${cliente.nombre}, ID: ${cliente.id}');
    }

    print('DEBUG - Productos cargados: ${productoProvider.productos.length}');
    for (final producto in productoProvider.productos) {
      print('  Producto: ${producto.nombre}, ID: ${producto.id}');
    }
  }

  void _calcularTotal() {
    if (_productoSeleccionado != null && _cantidadController.text.isNotEmpty) {
      final cantidad = int.tryParse(_cantidadController.text) ?? 0;
      setState(() {
        _total = _productoSeleccionado!.precio * cantidad;
      });
    } else {
      setState(() {
        _total = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Venta'),
        actions: [
          // Botón de diagnóstico temporal
          IconButton(
            onPressed: _mostrarDiagnostico,
            icon: const Icon(Icons.bug_report),
            tooltip: 'Diagnóstico',
          ),
          if (_cargando)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(onPressed: _guardarVenta, child: const Text('Guardar')),
        ],
      ),
      body: Consumer3<VentaProvider, ClienteProvider, ProductoProvider>(
        builder:
            (context, ventaProvider, clienteProvider, productoProvider, child) {
              if (clienteProvider.cargando || productoProvider.cargando) {
                return const LoadingWidget(mensaje: 'Cargando datos...');
              }

              // Verificar si hay errores en la carga de datos
              if (clienteProvider.error != null ||
                  productoProvider.error != null) {
                return Center(
                  child: Card(
                    margin: const EdgeInsets.all(16.0),
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error al cargar datos',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                          const SizedBox(height: 8),
                          if (clienteProvider.error != null)
                            Text('Clientes: ${clienteProvider.error}'),
                          if (productoProvider.error != null)
                            Text('Productos: ${productoProvider.error}'),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _cargarDatos,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Información de la Venta',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildClienteSelector(
                                    clienteProvider.clientes,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildProductoSelector(
                                    productoProvider.productos,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _cantidadController,
                                    decoration: const InputDecoration(
                                      labelText: 'Cantidad',
                                      hintText: '1',
                                      prefixIcon: Icon(Icons.shopping_cart),
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'La cantidad es obligatoria';
                                      }
                                      final cantidad = int.tryParse(
                                        value.trim(),
                                      );
                                      if (cantidad == null) {
                                        return 'Ingresa una cantidad válida';
                                      }
                                      if (cantidad <= 0) {
                                        return 'La cantidad debe ser mayor a 0';
                                      }
                                      if (cantidad > 999999) {
                                        return 'La cantidad es demasiado alta';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Resumen',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildResumen(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _cargando || !_formularioValido()
                                  ? null
                                  : _guardarVenta,
                              icon: _cargando
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.add),
                              label: const Text('Crear Venta'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                          if (ventaProvider.error != null) ...[
                            const SizedBox(height: 16),
                            Card(
                              color: Theme.of(
                                context,
                              ).colorScheme.errorContainer,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        ventaProvider.error!,
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (ventaProvider.cargando)
                    Container(
                      color: Colors.black.withOpacity(0.3),
                      child: const LoadingWidget(mensaje: 'Guardando venta...'),
                    ),
                ],
              );
            },
      ),
    );
  }

  Widget _buildClienteSelector(List<Cliente> clientes) {
    // Filtrar clientes que tengan ID válido
    final clientesValidos = clientes.where((c) => c.id != null).toList();

    if (clientesValidos.isEmpty) {
      return Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.warning_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No hay clientes disponibles con IDs válidos. Verifica la conexión con el servidor.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return DropdownButtonFormField<Cliente>(
      value: _clienteSeleccionado,
      isExpanded: true, // Permite que el dropdown use todo el ancho disponible
      decoration: const InputDecoration(
        labelText: 'Cliente',
        prefixIcon: Icon(Icons.person),
      ),
      hint: const Text('Selecciona un cliente'),
      items: clientesValidos.map((cliente) {
        return DropdownMenuItem<Cliente>(
          value: cliente,
          child: Text(
            Formatters.capitalize(cliente.nombre),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      onChanged: (cliente) {
        setState(() {
          _clienteSeleccionado = cliente;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Selecciona un cliente';
        }
        if (value.id == null) {
          return 'Cliente seleccionado no tiene ID válido';
        }
        return null;
      },
    );
  }

  Widget _buildProductoSelector(List<Producto> productos) {
    // Filtrar productos que tengan ID válido
    final productosValidos = productos.where((p) => p.id != null).toList();

    if (productosValidos.isEmpty) {
      return Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.warning_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No hay productos disponibles con IDs válidos. Verifica la conexión con el servidor.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return DropdownButtonFormField<Producto>(
      value: _productoSeleccionado,
      isExpanded: true, // Permite que el dropdown use todo el ancho disponible
      decoration: const InputDecoration(
        labelText: 'Producto',
        prefixIcon: Icon(Icons.inventory_2),
      ),
      hint: const Text('Selecciona un producto'),
      items: productosValidos.map((producto) {
        return DropdownMenuItem<Producto>(
          value: producto,
          child: Row(
            mainAxisSize: MainAxisSize.min, // Evita overflow horizontal
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  Formatters.capitalize(producto.nombre),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8), // Espaciado entre elementos
              Flexible(
                flex: 2,
                child: Text(
                  Formatters.formatPrice(producto.precio),
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (producto) {
        setState(() {
          _productoSeleccionado = producto;
        });
        _calcularTotal();
      },
      validator: (value) {
        if (value == null) {
          return 'Selecciona un producto';
        }
        if (value.id == null) {
          return 'Producto seleccionado no tiene ID válido';
        }
        return null;
      },
    );
  }

  Widget _buildResumen() {
    if (_clienteSeleccionado == null || _productoSeleccionado == null) {
      return Text(
        'Selecciona cliente y producto para ver el resumen',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      );
    }

    final cantidad = int.tryParse(_cantidadController.text) ?? 0;

    return Column(
      children: [
        _buildResumenItem('Cliente:', _clienteSeleccionado!.nombre),
        _buildResumenItem('Producto:', _productoSeleccionado!.nombre),
        _buildResumenItem(
          'Precio unitario:',
          Formatters.formatPrice(_productoSeleccionado!.precio),
        ),
        _buildResumenItem('Cantidad:', cantidad.toString()),
        const Divider(),
        _buildResumenItem(
          'Total estimado:',
          Formatters.formatPrice(_total),
          esTotal: true,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '* El total final será calculado por el servidor',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResumenItem(
    String etiqueta,
    String valor, {
    bool esTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            etiqueta,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: esTotal ? FontWeight.bold : null,
            ),
          ),
          Text(
            valor,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: esTotal ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  bool _formularioValido() {
    return _clienteSeleccionado != null &&
        _clienteSeleccionado!.id != null &&
        _productoSeleccionado != null &&
        _productoSeleccionado!.id != null &&
        _cantidadController.text.isNotEmpty &&
        int.tryParse(_cantidadController.text) != null &&
        int.parse(_cantidadController.text) > 0;
  }

  Future<void> _guardarVenta() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validar que los IDs no sean null
    if (_clienteSeleccionado?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Cliente seleccionado no tiene ID válido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_productoSeleccionado?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Producto seleccionado no tiene ID válido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _cargando = true;
    });

    final provider = context.read<VentaProvider>();
    provider.limpiarError();

    final venta = Venta.paraCrear(
      cantidad: int.parse(_cantidadController.text.trim()),
      clienteId: _clienteSeleccionado!.id!,
      productoId: _productoSeleccionado!.id!,
      cliente: _clienteSeleccionado,
      producto: _productoSeleccionado,
    );

    final exito = await provider.crearVenta(venta);

    setState(() {
      _cargando = false;
    });

    if (mounted) {
      if (exito) {
        // Llamar al callback si existe para actualización inmediata
        if (widget.onVentaSaved != null) {
          widget.onVentaSaved!();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Venta creada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retornar true para indicar éxito
      } else {
        // El error se muestra automáticamente en la UI través del Consumer
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Error al guardar venta'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Método temporal para diagnóstico
  void _mostrarDiagnostico() {
    final clienteProvider = context.read<ClienteProvider>();
    final productoProvider = context.read<ProductoProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Diagnóstico de Datos'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Clientes cargados: ${clienteProvider.clientes.length}'),
              for (final cliente in clienteProvider.clientes.take(5))
                Text('- ${cliente.nombre} (ID: ${cliente.id})'),
              if (clienteProvider.clientes.length > 5)
                Text('... y ${clienteProvider.clientes.length - 5} más'),
              const SizedBox(height: 16),
              Text('Productos cargados: ${productoProvider.productos.length}'),
              for (final producto in productoProvider.productos.take(5))
                Text('- ${producto.nombre} (ID: ${producto.id})'),
              if (productoProvider.productos.length > 5)
                Text('... y ${productoProvider.productos.length - 5} más'),
              const SizedBox(height: 16),
              if (clienteProvider.error != null)
                Text(
                  'Error clientes: ${clienteProvider.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              if (productoProvider.error != null)
                Text(
                  'Error productos: ${productoProvider.error}',
                  style: const TextStyle(color: Colors.red),
                ),
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
