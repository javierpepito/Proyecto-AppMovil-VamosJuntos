import 'user_model.dart';

class MensajeModel {
  final String id;
  final String chatId;
  final String usuarioId;
  final String contenido;
  final DateTime horaEnviado;
  
  // Relación con usuario (opcional, viene del join)
  final UserModel? usuario;

  MensajeModel({
    required this.id,
    required this.chatId,
    required this.usuarioId,
    required this.contenido,
    required this.horaEnviado,
    this.usuario,
  });

  // Obtener hora de Chile
  DateTime get _chileTime {
    return DateTime.now().toUtc().subtract(const Duration(hours: 3));
  }

  // Verificar si el mensaje es del usuario actual
  bool esMio(String currentUserId) => usuarioId == currentUserId;

  // Hora formateada "14:30" (en hora de Chile)
  String get horaFormateada {
    return '${horaEnviado.hour.toString().padLeft(2, '0')}:${horaEnviado.minute.toString().padLeft(2, '0')}';
  }

  // Fecha formateada "Hoy", "Ayer", o "dd/MM/yyyy"
  String get fechaFormateada {
    final ahora = _chileTime; 
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final ayer = hoy.subtract(const Duration(days: 1));
    final fechaMensaje = DateTime(horaEnviado.year, horaEnviado.month, horaEnviado.day);
    
    if (fechaMensaje == hoy) {
      return 'Hoy';
    } else if (fechaMensaje == ayer) {
      return 'Ayer';
    } else {
      return '${horaEnviado.day.toString().padLeft(2, '0')}/${horaEnviado.month.toString().padLeft(2, '0')}/${horaEnviado.year}';
    }
  }

  // Convertir de JSON a objeto
  factory MensajeModel.fromJson(Map<String, dynamic> json) {
    // Parsear con ajuste de timezone de Chile
    final utcTime = DateTime.parse(json['hora_enviado'] as String);
    final chileTime = utcTime.subtract(const Duration(hours: 3)); // Ajustar a Chile
    
    return MensajeModel(
      id: json['id'] as String,
      chatId: json['chat_id'] as String,
      usuarioId: json['usuario_id'] as String,
      contenido: json['contenido'] as String,
      horaEnviado: chileTime,
      usuario: json['usuario'] != null 
          ? UserModel.fromJson(json['usuario'] as Map<String, dynamic>)
          : null,
    );
  }

  // Convertir de objeto a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'usuario_id': usuarioId,
      'contenido': contenido,
      'hora_enviado': horaEnviado.toIso8601String(),
    };
  }

  @override
  String toString() => 'MensajeModel(id: $id, usuario: ${usuario?.nombreCompleto}, contenido: $contenido)';
}