class ChatModel {
  final String id;
  final String paradero;
  final String horaInicio;
  final String horaTermino;
  final DateTime fecha;
  final String estado;

  ChatModel({
    required this.id,
    required this.paradero,
    required this.horaInicio,
    required this.horaTermino,
    required this.fecha,
    required this.estado,
  });

  // Obtener horario formateado "08:00 - 09:00"
  String get horarioFormateado {
    return '$horaInicio - $horaTermino';
  }

  // Verificar si el chat está activo en BD
  bool get estaActivo => estado == 'activo';

  // Verificar si el chat está realmente disponible (combina BD + tiempo real)
  bool get estaDisponible {
    // Si está cerrado en BD, no está disponible
    if (estado != 'activo') return false;
    
    final ahora = DateTime.now();
    
    // Verificar que sea hoy
    final esHoy = fecha.year == ahora.year && 
                  fecha.month == ahora.month && 
                  fecha.day == ahora.day;
    
    if (!esHoy) return false;
    
    // Verificar que no haya pasado la hora de término
    final horaTerminoParts = horaTermino.split(':');
    final terminoHoy = DateTime(
      ahora.year, ahora.month, ahora.day,
      int.parse(horaTerminoParts[0]),
      int.parse(horaTerminoParts[1])
    );
    
    // El chat está disponible si aún no ha terminado
    return ahora.isBefore(terminoHoy);
  }

  // Verificar si el chat ya pasó su hora
  bool get yaPaso {
    if (estado == 'finalizado' || estado == 'cerrado') return true;
    
    final ahora = DateTime.now();
    
    // Si no es hoy, ya pasó
    final esHoy = fecha.year == ahora.year && 
                  fecha.month == ahora.month && 
                  fecha.day == ahora.day;
    
    if (!esHoy) return true;
    
    // Verificar si pasó la hora de término
    final horaTerminoParts = horaTermino.split(':');
    final terminoHoy = DateTime(
      ahora.year, ahora.month, ahora.day,
      int.parse(horaTerminoParts[0]),
      int.parse(horaTerminoParts[1])
    );
    
    return ahora.isAfter(terminoHoy);
  }

  // Verificar si está próximo a comenzar (15 min antes)
  bool get proximoAComenzar {
    if (!estaDisponible) return false;
    
    final ahora = DateTime.now();
    final horaInicioParts = horaInicio.split(':');
    final inicioHoy = DateTime(
      ahora.year, ahora.month, ahora.day,
      int.parse(horaInicioParts[0]),
      int.parse(horaInicioParts[1])
    );
    
    final diferencia = inicioHoy.difference(ahora).inMinutes;
    return diferencia <= 15 && diferencia >= 0;
  }

  // Verificar si está próximo a cerrar (menos de 15 min)
  bool get proximoACerrar {
    if (!estaDisponible) return false;
    
    final ahora = DateTime.now();
    final horaTerminoParts = horaTermino.split(':');
    final termino = DateTime(
      ahora.year, ahora.month, ahora.day,
      int.parse(horaTerminoParts[0]),
      int.parse(horaTerminoParts[1])
    );
    
    final diferencia = termino.difference(ahora).inMinutes;
    return diferencia <= 15 && diferencia > 0;
  }

  // Obtener estado visual para mostrar en UI
  String get estadoVisual {
    if (yaPaso) return 'Finalizado';
    if (proximoACerrar) return 'Por cerrar';
    if (proximoAComenzar) return 'Próximo';
    if (estaDisponible) return 'Activo';
    return 'No disponible';
  }

  // Debería actualizarse en BD
  bool get deberiaActualizarseEnBD {
    // Si ya pasó pero sigue activo en BD, necesita actualizarse
    return yaPaso && estado == 'activo';
  }

  // Convertir de JSON a objeto
  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] as String,
      paradero: json['paradero'] as String,
      horaInicio: json['hora_inicio'] as String,
      horaTermino: json['hora_termino'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      estado: json['estado'] as String? ?? 'activo',
    );
  }

  // Convertir de objeto a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paradero': paradero,
      'hora_inicio': horaInicio,
      'hora_termino': horaTermino,
      'fecha': fecha.toIso8601String().split('T')[0],
      'estado': estado,
    };
  }

  @override
  String toString() => 'ChatModel(id: $id, paradero: $paradero, horario: $horarioFormateado, estado: $estado)';
}