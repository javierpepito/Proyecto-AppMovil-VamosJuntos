class UserModel {
  final String id;
  final String nombre;
  final String apellido;
  final String email;
  final String carrera;
  final String telefonoPersonal;

  UserModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.carrera,
    required this.telefonoPersonal,
  });

  // Nombre completo
  String get nombreCompleto => '$nombre $apellido';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String? ?? '',
      apellido: json['apellido'] as String? ?? '',
      email: json['email'] as String,
      carrera: json['carrera'] as String? ?? '',
      telefonoPersonal: json['telefono_personal'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'carrera': carrera,
      'telefono_personal': telefonoPersonal,
    };
  }
}