class Cliente {
  final int? id;
  final String nombre;
  final String email;

  Cliente({this.id, required this.nombre, required this.email});

  // Crear Cliente desde JSON
  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'] as int?,
      nombre: json['nombre'] as String,
      email: json['email'] as String,
    );
  }

  // Convertir Cliente a JSON
  Map<String, dynamic> toJson() {
    return {if (id != null) 'id': id, 'nombre': nombre, 'email': email};
  }

  // Crear copia con modificaciones
  Cliente copyWith({int? id, String? nombre, String? email}) {
    return Cliente(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
    );
  }

  @override
  String toString() {
    return 'Cliente{id: $id, nombre: $nombre, email: $email}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cliente &&
        other.id == id &&
        other.nombre == nombre &&
        other.email == email;
  }

  @override
  int get hashCode => Object.hash(id, nombre, email);
}
