class NotificacionHistorialModel {
  final String id;
  final String titulo;
  final String mensaje;
  final DateTime fecha;
  final String tipo; // '10min' o 'momento'
  final String? salidaId;
  final String? puntoEncuentro;
  final bool leida;

  NotificacionHistorialModel({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.fecha,
    required this.tipo,
    this.salidaId,
    this.puntoEncuentro,
    this.leida = false,
  });

  // Convertir de JSON a objeto
  factory NotificacionHistorialModel.fromJson(Map<String, dynamic> json) {
    return NotificacionHistorialModel(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      mensaje: json['mensaje'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      tipo: json['tipo'] as String,
      salidaId: json['salidaId'] as String?,
      puntoEncuentro: json['puntoEncuentro'] as String?,
      leida: json['leida'] as bool? ?? false,
    );
  }

  // Convertir de objeto a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'mensaje': mensaje,
      'fecha': fecha.toIso8601String(),
      'tipo': tipo,
      'salidaId': salidaId,
      'puntoEncuentro': puntoEncuentro,
      'leida': leida,
    };
  }

  // Copiar con modificaciones
  NotificacionHistorialModel copyWith({
    String? id,
    String? titulo,
    String? mensaje,
    DateTime? fecha,
    String? tipo,
    String? salidaId,
    String? puntoEncuentro,
    bool? leida,
  }) {
    return NotificacionHistorialModel(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      mensaje: mensaje ?? this.mensaje,
      fecha: fecha ?? this.fecha,
      tipo: tipo ?? this.tipo,
      salidaId: salidaId ?? this.salidaId,
      puntoEncuentro: puntoEncuentro ?? this.puntoEncuentro,
      leida: leida ?? this.leida,
    );
  }

  // Tiempo transcurrido desde la notificación
  String get tiempoTranscurrido {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inDays > 0) {
      return 'Hace ${diferencia.inDays} día${diferencia.inDays > 1 ? 's' : ''}';
    } else if (diferencia.inHours > 0) {
      return 'Hace ${diferencia.inHours} hora${diferencia.inHours > 1 ? 's' : ''}';
    } else if (diferencia.inMinutes > 0) {
      return 'Hace ${diferencia.inMinutes} minuto${diferencia.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'Justo ahora';
    }
  }

  // Icono según el tipo
  String get icono {
    switch (tipo) {
      case '10min':
        return '⏰';
      case 'momento':
        return '🚌';
      default:
        return '🔔';
    }
  }

  @override
  String toString() => 'NotificacionHistorialModel(id: $id, titulo: $titulo, fecha: $fecha, tipo: $tipo)';
}
