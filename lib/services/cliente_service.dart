import '../config/api_config.dart';
import '../models/cliente.dart';
import 'base_api_service.dart';

class ClienteService extends BaseApiService {
  // Obtener todos los clientes
  Future<List<Cliente>> obtenerClientes() async {
    final response = await get(ApiConfig.clientesEndpoint);

    if (response is List) {
      return response.map((json) => Cliente.fromJson(json)).toList();
    }

    return [];
  }

  // Obtener cliente por ID
  Future<Cliente> obtenerClientePorId(int id) async {
    final response = await get('${ApiConfig.clientesEndpoint}/$id');
    return Cliente.fromJson(response);
  }

  // Crear nuevo cliente
  Future<Cliente> crearCliente(Cliente cliente) async {
    // Solo enviar campos que acepta el CreateClienteDto
    final datosCreacion = {'nombre': cliente.nombre, 'email': cliente.email};

    final response = await post(ApiConfig.clientesEndpoint, datosCreacion);
    return Cliente.fromJson(response);
  }

  // Actualizar cliente existente
  Future<Cliente> actualizarCliente(int id, Cliente cliente) async {
    // Solo enviar campos que acepta el UpdateClienteDto
    final datosActualizacion = {
      'nombre': cliente.nombre,
      'email': cliente.email,
    };

    final response = await put(
      '${ApiConfig.clientesEndpoint}/$id',
      datosActualizacion,
    );
    return Cliente.fromJson(response);
  }

  // Eliminar cliente
  Future<void> eliminarCliente(int id) async {
    await delete('${ApiConfig.clientesEndpoint}/$id');
  }

  // Buscar clientes por nombre
  Future<List<Cliente>> buscarClientesPorNombre(String nombre) async {
    final clientes = await obtenerClientes();
    return clientes
        .where(
          (cliente) =>
              cliente.nombre.toLowerCase().contains(nombre.toLowerCase()),
        )
        .toList();
  }

  // Validar si el email ya existe
  Future<bool> emailExiste(String email, {int? clienteIdExcluir}) async {
    final clientes = await obtenerClientes();
    return clientes.any(
      (cliente) =>
          cliente.email.toLowerCase() == email.toLowerCase() &&
          (clienteIdExcluir == null || cliente.id != clienteIdExcluir),
    );
  }
}
