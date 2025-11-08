class SalidaModel {
  final String id;
  final String? chatId;
  final String puntoEncuentro;
  final DateTime horaSalida;
  final String estado;

  SalidaModel({
    required this.id,
    this.chatId,
    required this.puntoEncuentro,
    required this.horaSalida,
    required this.estado,
  });

  // Verificar si la salida está abierta
  bool get estaAbierta => estado == 'abierta';

  // Verificar si está disponible (abierta y no ha pasado la hora)
  bool get estaDisponible {
    if (estado != 'abierta') return false;
    return DateTime.now().isBefore(horaSalida);
  }

  // Verificar si está en progreso
  bool get enProgreso => estado == 'en_progreso';

  // Hora formateada "14:30"
  String get horaFormateada {
    return '${horaSalida.hour.toString().padLeft(2, '0')}:${horaSalida.minute.toString().padLeft(2, '0')}';
  }

  // Tiempo restante hasta la salida
  String get tiempoRestante {
    final ahora = DateTime.now();
    if (horaSalida.isBefore(ahora)) {
      return 'Ya partió';
    }
    
    final diferencia = horaSalida.difference(ahora);
    
    if (diferencia.inHours > 0) {
      return '${diferencia.inHours}h ${diferencia.inMinutes % 60}min';
    } else if (diferencia.inMinutes > 0) {
      return '${diferencia.inMinutes}min';
    } else {
      return 'Saliendo ahora';
    }
  }

  // Convertir de JSON a objeto
  factory SalidaModel.fromJson(Map<String, dynamic> json) {
    return SalidaModel(
      id: json['id'] as String,
      chatId: json['chat_id'] as String?,
      puntoEncuentro: json['punto_encuentro'] as String,
      horaSalida: DateTime.parse(json['hora_salida'] as String),
      estado: json['estado'] as String? ?? 'abierta',
    );
  }

  // Convertir de objeto a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'punto_encuentro': puntoEncuentro,
      'hora_salida': horaSalida.toIso8601String(),
      'estado': estado,
    };
  }

  @override
  String toString() => 'SalidaModel(id: $id, punto: $puntoEncuentro, hora: $horaFormateada, estado: $estado)';
}