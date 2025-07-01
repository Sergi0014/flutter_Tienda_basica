import '../config/api_config.dart';
import '../models/producto.dart';
import 'base_api_service.dart';

class ProductoService extends BaseApiService {
  // Obtener todos los productos
  Future<List<Producto>> obtenerProductos() async {
    final response = await get(ApiConfig.productosEndpoint);

    if (response is List) {
      return response.map((json) => Producto.fromJson(json)).toList();
    }

    return [];
  }

  // Obtener producto por ID
  Future<Producto> obtenerProductoPorId(int id) async {
    final response = await get('${ApiConfig.productosEndpoint}/$id');
    return Producto.fromJson(response);
  }

  // Crear nuevo producto
  Future<Producto> crearProducto(Producto producto) async {
    // Solo enviar campos que acepta el CreateProductoDto
    final datosCreacion = {
      'nombre': producto.nombre,
      'precio': producto.precio,
    };

    final response = await post(ApiConfig.productosEndpoint, datosCreacion);
    return Producto.fromJson(response);
  }

  // Actualizar producto existente
  Future<Producto> actualizarProducto(int id, Producto producto) async {
    // Solo enviar campos que acepta el UpdateProductoDto
    final datosActualizacion = {
      'nombre': producto.nombre,
      'precio': producto.precio,
    };

    final response = await put(
      '${ApiConfig.productosEndpoint}/$id',
      datosActualizacion,
    );
    return Producto.fromJson(response);
  }

  // Eliminar producto
  Future<void> eliminarProducto(int id) async {
    await delete('${ApiConfig.productosEndpoint}/$id');
  }

  // Buscar productos por nombre
  Future<List<Producto>> buscarProductosPorNombre(String nombre) async {
    final productos = await obtenerProductos();
    return productos
        .where(
          (producto) =>
              producto.nombre.toLowerCase().contains(nombre.toLowerCase()),
        )
        .toList();
  }

  // Obtener productos por rango de precio
  Future<List<Producto>> obtenerProductosPorRangoPrecio(
    double precioMin,
    double precioMax,
  ) async {
    final productos = await obtenerProductos();
    return productos
        .where(
          (producto) =>
              producto.precio >= precioMin && producto.precio <= precioMax,
        )
        .toList();
  }

  // Validar si el nombre ya existe
  Future<bool> nombreExiste(String nombre, {int? productoIdExcluir}) async {
    final productos = await obtenerProductos();
    return productos.any(
      (producto) =>
          producto.nombre.toLowerCase() == nombre.toLowerCase() &&
          (productoIdExcluir == null || producto.id != productoIdExcluir),
    );
  }
}
