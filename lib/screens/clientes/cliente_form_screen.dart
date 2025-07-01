import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/cliente.dart';
import '../../providers/cliente_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/loading_widget.dart';

class ClienteFormScreen extends StatefulWidget {
  final Cliente? cliente;
  final VoidCallback? onClienteSaved;

  const ClienteFormScreen({super.key, this.cliente, this.onClienteSaved});

  @override
  State<ClienteFormScreen> createState() => _ClienteFormScreenState();
}

class _ClienteFormScreenState extends State<ClienteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();

  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    print(
      'DEBUG ClienteForm - Iniciando con cliente: ${widget.cliente?.toString()}',
    );
    if (widget.cliente != null) {
      _nombreController.text = widget.cliente!.nombre;
      _emailController.text = widget.cliente!.email;
      print(
        'DEBUG ClienteForm - Datos cargados - Nombre: ${widget.cliente!.nombre}, Email: ${widget.cliente!.email}, ID: ${widget.cliente!.id}',
      );
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool get _esEdicion => widget.cliente != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar Cliente' : 'Nuevo Cliente'),
        actions: [
          // Botón de diagnóstico temporal
          IconButton(
            onPressed: _mostrarDiagnostico,
            icon: const Icon(Icons.bug_report),
            tooltip: 'Diagnóstico',
          ),
          // Botón de prueba de conectividad
          IconButton(
            onPressed: _probarConectividad,
            icon: const Icon(Icons.wifi_find),
            tooltip: 'Probar conexión',
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
            TextButton(
              onPressed: _guardarCliente,
              child: const Text('Guardar'),
            ),
        ],
      ),
      body: Consumer<ClienteProvider>(
        builder: (context, provider, child) {
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
                                'Información del Cliente',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _nombreController,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre completo',
                                  hintText: 'Ingresa el nombre del cliente',
                                  prefixIcon: Icon(Icons.person),
                                ),
                                textCapitalization: TextCapitalization.words,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'El nombre es obligatorio';
                                  }
                                  if (value.trim().length < 2) {
                                    return 'El nombre debe tener al menos 2 caracteres';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Correo electrónico',
                                  hintText: 'ejemplo@correo.com',
                                  prefixIcon: Icon(Icons.email),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'El email es obligatorio';
                                  }
                                  if (!Formatters.isValidEmail(value.trim())) {
                                    return 'Ingresa un email válido';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _cargando ? null : _guardarCliente,
                          icon: _cargando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(_esEdicion ? Icons.save : Icons.add),
                          label: Text(
                            _esEdicion ? 'Actualizar Cliente' : 'Crear Cliente',
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      if (provider.error != null) ...[
                        const SizedBox(height: 16),
                        Card(
                          color: Theme.of(context).colorScheme.errorContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    provider.error!,
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
              if (provider.cargando)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const LoadingWidget(mensaje: 'Guardando cliente...'),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _guardarCliente() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validar que el ID no sea null para edición
    if (_esEdicion && widget.cliente?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Cliente seleccionado no tiene ID válido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _cargando = true;
    });

    final provider = context.read<ClienteProvider>();
    provider.limpiarError();

    print('DEBUG ClienteForm - Creando cliente con datos:');
    print('  - ID: ${widget.cliente?.id}');
    print('  - Nombre: ${_nombreController.text.trim()}');
    print('  - Email: ${_emailController.text.trim().toLowerCase()}');

    final cliente = Cliente(
      id: widget.cliente?.id,
      nombre: _nombreController.text.trim(),
      email: _emailController.text.trim().toLowerCase(),
    );

    print('DEBUG ClienteForm - Cliente creado: ${cliente.toString()}');

    bool exito;
    if (_esEdicion) {
      print(
        'DEBUG ClienteForm - Actualizando cliente con ID: ${widget.cliente!.id}',
      );
      exito = await provider.actualizarCliente(widget.cliente!.id!, cliente);
    } else {
      print('DEBUG ClienteForm - Creando nuevo cliente');
      exito = await provider.crearCliente(cliente);
    }

    setState(() {
      _cargando = false;
    });

    if (mounted) {
      if (exito) {
        // Llamar al callback si existe para actualización inmediata
        if (widget.onClienteSaved != null) {
          widget.onClienteSaved!();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _esEdicion
                  ? 'Cliente actualizado exitosamente'
                  : 'Cliente creado exitosamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retornar true para indicar éxito
      } else {
        // El error se muestra automáticamente en la UI través del Consumer
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Error al guardar cliente'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Método temporal para diagnóstico
  void _mostrarDiagnostico() {
    final provider = context.read<ClienteProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Diagnóstico de Cliente'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Modo: ${_esEdicion ? "Edición" : "Creación"}'),
              const SizedBox(height: 8),
              if (_esEdicion) ...[
                Text('Cliente actual:'),
                Text('- Nombre: ${widget.cliente?.nombre}'),
                Text('- Email: ${widget.cliente?.email}'),
                Text('- ID: ${widget.cliente?.id}'),
                const SizedBox(height: 8),
              ],
              Text('Datos del formulario:'),
              Text('- Nombre: ${_nombreController.text}'),
              Text('- Email: ${_emailController.text}'),
              const SizedBox(height: 8),
              Text('Estado del provider:'),
              Text('- Cargando: ${provider.cargando}'),
              Text('- Error: ${provider.error ?? "Ninguno"}'),
              Text('- Clientes en memoria: ${provider.clientes.length}'),
              const SizedBox(height: 8),
              if (provider.error != null)
                Text(
                  'Detalles del error:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              if (provider.error != null)
                Text(
                  provider.error!,
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

  // Método para probar conectividad con el backend
  Future<void> _probarConectividad() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Probando conectividad...'),
          ],
        ),
      ),
    );

    try {
      final provider = context.read<ClienteProvider>();
      await provider.cargarClientes();

      Navigator.pop(context); // Cerrar dialog de carga

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Prueba de Conectividad'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('✅ Conexión exitosa'),
              const SizedBox(height: 8),
              Text('Clientes encontrados: ${provider.clientes.length}'),
              const SizedBox(height: 8),
              if (provider.clientes.isNotEmpty) ...[
                const Text('Ejemplos:'),
                for (final cliente in provider.clientes.take(3))
                  Text('- ${cliente.nombre} (ID: ${cliente.id})'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Cerrar dialog de carga

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error de Conectividad'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('❌ Error al conectar'),
              const SizedBox(height: 8),
              Text('Detalles: $e'),
            ],
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
}
