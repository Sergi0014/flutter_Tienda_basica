import 'cliente.dart';
import 'producto.dart';

class Venta {
  final int? id;
  final int cantidad;
  final double total;
  final int clienteId;
  final int productoId;
  final Cliente? cliente;
  final Producto? producto;

  Venta({
    this.id,
    required this.cantidad,
    this.total = 0.0, // Valor por defecto ya que será calculado por el backend
    required this.clienteId,
    required this.productoId,
    this.cliente,
    this.producto,
  });

  // Constructor para crear venta sin total (será calculado por el backend)
  Venta.paraCrear({
    required this.cantidad,
    required this.clienteId,
    required this.productoId,
    this.cliente,
    this.producto,
  }) : id = null,
       total = 0.0;

  // Crear Venta desde JSON
  factory Venta.fromJson(Map<String, dynamic> json) {
    return Venta(
      id: json['id'] as int?,
      cantidad: json['cantidad'] as int,
      total: (json['total'] as num).toDouble(),
      clienteId: json['clienteId'] as int,
      productoId: json['productoId'] as int,
      cliente: json['cliente'] != null
          ? Cliente.fromJson(json['cliente'])
          : null,
      producto: json['producto'] != null
          ? Producto.fromJson(json['producto'])
          : null,
    );
  }

  // Convertir Venta a JSON
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'cantidad': cantidad,
      'total': total,
      'clienteId': clienteId,
      'productoId': productoId,
    };

    // Solo incluir el ID si no es null (para actualizaciones)
    if (id != null) {
      json['id'] = id;
    }

    return json;
  }

  // Crear un JSON para creación (sin ID y sin total - solo campos del DTO)
  Map<String, dynamic> toJsonForCreate() {
    return {
      'clienteId': clienteId,
      'productoId': productoId,
      'cantidad': cantidad,
    };
  }

  // Crear un JSON para actualización (solo campos que acepta el UpdateVentaDto)
  Map<String, dynamic> toJsonForUpdate() {
    return {
      'clienteId': clienteId,
      'productoId': productoId,
      'cantidad': cantidad,
    };
  }

  // Validar datos de la venta (sin total ya que se calcula en el backend)
  bool get isValid {
    return cantidad > 0 && clienteId > 0 && productoId > 0;
  }

  // Obtener mensaje de validación
  String? get validationMessage {
    if (cantidad <= 0) return 'La cantidad debe ser mayor a 0';
    if (clienteId <= 0) return 'Debe seleccionar un cliente';
    if (productoId <= 0) return 'Debe seleccionar un producto';
    return null;
  }

  // Crear copia con modificaciones
  Venta copyWith({
    int? id,
    int? cantidad,
    double? total,
    int? clienteId,
    int? productoId,
    Cliente? cliente,
    Producto? producto,
  }) {
    return Venta(
      id: id ?? this.id,
      cantidad: cantidad ?? this.cantidad,
      total: total ?? this.total,
      clienteId: clienteId ?? this.clienteId,
      productoId: productoId ?? this.productoId,
      cliente: cliente ?? this.cliente,
      producto: producto ?? this.producto,
    );
  }

  @override
  String toString() {
    return 'Venta{id: $id, cantidad: $cantidad, total: $total, clienteId: $clienteId, productoId: $productoId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Venta &&
        other.id == id &&
        other.cantidad == cantidad &&
        other.total == total &&
        other.clienteId == clienteId &&
        other.productoId == productoId;
  }

  @override
  int get hashCode => Object.hash(id, cantidad, total, clienteId, productoId);
}
