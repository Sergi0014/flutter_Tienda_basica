class Producto {
  final int? id;
  final String nombre;
  final double precio;

  Producto({this.id, required this.nombre, required this.precio});

  // Crear Producto desde JSON
  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] as int?,
      nombre: json['nombre'] as String,
      precio: (json['precio'] as num).toDouble(),
    );
  }

  // Convertir Producto a JSON
  Map<String, dynamic> toJson() {
    return {if (id != null) 'id': id, 'nombre': nombre, 'precio': precio};
  }

  // Crear copia con modificaciones
  Producto copyWith({int? id, String? nombre, double? precio}) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
    );
  }

  @override
  String toString() {
    return 'Producto{id: $id, nombre: $nombre, precio: $precio}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Producto &&
        other.id == id &&
        other.nombre == nombre &&
        other.precio == precio;
  }

  @override
  int get hashCode => Object.hash(id, nombre, precio);
}
