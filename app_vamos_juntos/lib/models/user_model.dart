class UserModel {
  final String id;
  final String email;
  final String carrera;
  final String telefonoPersonal;

  UserModel({
    required this.id,
    required this.email,
    required this.carrera,
    required this.telefonoPersonal,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      carrera: json['carrera'] as String? ?? '',
      telefonoPersonal: json['telefono_personal'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'carrera': carrera,
      'telefono_personal': telefonoPersonal,
    };
  }
}