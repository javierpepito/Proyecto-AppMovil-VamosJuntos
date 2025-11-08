class UserModel {
  final String id;
  final String nombre;
  final String apellido;
  final String? carrera;
  final String? telefonoPersonal;
  final String email;

  UserModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    this.carrera,
    this.telefonoPersonal,
    required this.email,
  });

  // Nombre completo
  String get nombreCompleto => '$nombre $apellido';

  // Iniciales
  String get iniciales {
    final n = nombre.isNotEmpty ? nombre[0].toUpperCase() : '';
    final a = apellido.isNotEmpty ? apellido[0].toUpperCase() : '';
    return '$n$a';
  }

  // Convertir de JSON a objeto
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String? ?? '',
      apellido: json['apellido'] as String? ?? '',
      carrera: json['carrera'] as String?,
      telefonoPersonal: json['telefono_personal'] as String?,
      email: json['email'] as String,
    );
  }

  // Convertir de objeto a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'carrera': carrera,
      'telefono_personal': telefonoPersonal,
      'email': email,
    };
  }

  // Copiar con modificaciones
  UserModel copyWith({
    String? id,
    String? nombre,
    String? apellido,
    String? carrera,
    String? telefonoPersonal,
    String? email,
  }) {
    return UserModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      carrera: carrera ?? this.carrera,
      telefonoPersonal: telefonoPersonal ?? this.telefonoPersonal,
      email: email ?? this.email,
    );
  }

  @override
  String toString() => 'UserModel(id: $id, nombre: $nombreCompleto, email: $email)';
}