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

  // Obtener horario formateado "08:00 - 08:59"
  String get horarioFormateado {
    return '$horaInicio - $horaTermino';
  }

  // Verificar si el chat está activo
  bool get estaActivo => estado == 'activo';

  // Verificar si el chat está disponible (activo y no ha pasado la hora)
  bool get estaDisponible {
    if (estado != 'activo') return false;
    
    final ahora = DateTime.now();
    
    // Verificar que sea hoy
    if (fecha.day != ahora.day || 
        fecha.month != ahora.month || 
        fecha.year != ahora.year) {
      return false;
    }
    
    // Verificar que no haya pasado la hora
    final horaTerminoParts = horaTermino.split(':');
    final termino = DateTime(
      ahora.year, ahora.month, ahora.day,
      int.parse(horaTerminoParts[0]),
      int.parse(horaTerminoParts[1])
    );
    
    return ahora.isBefore(termino);
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