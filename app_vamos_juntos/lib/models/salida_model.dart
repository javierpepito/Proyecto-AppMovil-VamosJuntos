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

  // Verificar si la salida está abierta en BD
  bool get estaAbierta => estado == 'abierta';

  // Verificar si está realmente disponible (BD + tiempo real)
  bool get estaDisponible {
    if (estado != 'abierta') return false;
    
    final ahora = DateTime.now();
    // La salida está disponible hasta 5 minutos después de la hora
    // (para dar tiempo a llegar al punto de encuentro)
    final margen = horaSalida.add(const Duration(minutes: 5));
    
    return ahora.isBefore(margen);
  }

  // Verificar si ya pasó
  bool get yaPaso {
    if (estado == 'cerrada' || estado == 'cancelada') return true;
    
    final ahora = DateTime.now();
    final margen = horaSalida.add(const Duration(minutes: 5));
    
    return ahora.isAfter(margen);
  }

  // Verificar si está en progreso
  bool get enProgreso => estado == 'en_progreso';

  // Verificar si está próxima (menos de 10 minutos)
  bool get estaProxima {
    if (!estaDisponible) return false;
    
    final ahora = DateTime.now();
    final diferencia = horaSalida.difference(ahora).inMinutes;
    
    return diferencia <= 10 && diferencia >= 0;
  }

  // Hora formateada "14:30"
  String get horaFormateada {
    return '${horaSalida.hour.toString().padLeft(2, '0')}:${horaSalida.minute.toString().padLeft(2, '0')}';
  }

  // Tiempo restante hasta la salida
  String get tiempoRestante {
    final ahora = DateTime.now();
    
    if (yaPaso) {
      return 'Ya partió';
    }
    
    final diferencia = horaSalida.difference(ahora);
    
    if (diferencia.inHours > 0) {
      return '${diferencia.inHours}h ${diferencia.inMinutes % 60}min';
    } else if (diferencia.inMinutes > 0) {
      return '${diferencia.inMinutes}min';
    } else if (diferencia.inSeconds > 0) {
      return 'Saliendo ahora';
    } else {
      return 'Ya partió';
    }
  }

  // Estado visual
  String get estadoVisual {
    if (yaPaso) return 'Finalizada';
    if (estaProxima) return 'Próxima';
    if (estaDisponible) return 'Disponible';
    return 'No disponible';
  }

  // Debería actualizarse en BD
  bool get deberiaActualizarseEnBD {
    return yaPaso && estado == 'abierta';
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