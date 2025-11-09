import 'user_model.dart';

class SalidaParticipanteModel {
  final String id;
  final String salidaId;
  final String usuarioId;
  final String? micro;
  
  // Relación con usuario (opcional, viene del join)
  final UserModel? usuario;

  SalidaParticipanteModel({
    required this.id,
    required this.salidaId,
    required this.usuarioId,
    this.micro,
    this.usuario,
  });

  // Convertir de JSON a objeto
  factory SalidaParticipanteModel.fromJson(Map<String, dynamic> json) {
    return SalidaParticipanteModel(
      id: json['id'] as String,
      salidaId: json['salida_id'] as String,
      usuarioId: json['usuario_id'] as String,
      micro: json['micro'] as String?,
      usuario: json['usuario'] != null 
          ? UserModel.fromJson(json['usuario'] as Map<String, dynamic>)
          : null,
    );
  }

  // Convertir de objeto a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'salida_id': salidaId,
      'usuario_id': usuarioId,
      'micro': micro,
    };
  }

  @override
  String toString() => 'SalidaParticipanteModel(id: $id, usuario: ${usuario?.nombreCompleto}, micro: $micro)';
}