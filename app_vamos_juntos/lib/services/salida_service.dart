import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../main.dart';
import '../models/salida_model.dart';
import '../models/salida_participante_model.dart';

class SalidaService {
  static final SalidaService _instance = SalidaService._internal();
  factory SalidaService() => _instance;
  SalidaService._internal();

  /// Obtener salidas de un chat
  Future<List<SalidaModel>> obtenerSalidasDeChat(String chatId) async {
    try {
      final response = await supabase
          .from('salidas')
          .select()
          .eq('chat_id', chatId)
          .order('hora_salida', ascending: true);

      return (response as List)
          .map((json) => SalidaModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener salidas: $e');
    }
  }

  /// Obtener una salida específica
  Future<SalidaModel> obtenerSalida(String salidaId) async {
    try {
      final response = await supabase
          .from('salidas')
          .select()
          .eq('id', salidaId)
          .single();

      return SalidaModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener salida: $e');
    }
  }

  Future<void> unirseASalida(String salidaId, String usuarioId, {String? micro}) async {
    try {
      final salidaActiva = await _tieneSalidaActiva(usuarioId);
      if (salidaActiva != null) {
        throw Exception(
          'Ya estás en otra salida grupal a las ${salidaActiva.horaFormateada}. '
          'Debes salir de esa salida primero.'
        );
      }

      // Verificar que la salida esté disponible
      final salida = await obtenerSalida(salidaId);
      if (!salida.estaDisponible) {
        throw Exception('Esta salida ya no está disponible');
      }

      await supabase.from('salida_participantes').insert({
        'salida_id': salidaId,
        'usuario_id': usuarioId,
        'micro': micro,
      });

      debugPrint('✅ Usuario unido a la salida');
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // Ya está unido, actualizar micro si se proporcionó
        if (micro != null) {
          await actualizarMicro(salidaId, usuarioId, micro);
        }
        return;
      }
      throw Exception('Error al unirse a la salida: ${e.message}');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<SalidaModel?> _tieneSalidaActiva(String usuarioId) async {
    try {
      final response = await supabase
          .from('salida_participantes')
          .select('salida_id, salidas!inner(*)')
          .eq('usuario_id', usuarioId);

      final participaciones = response as List;
      
      if (participaciones.isEmpty) return null;

      // Buscar la primera salida disponible
      for (var participacion in participaciones) {
        final salidaData = participacion['salidas'];
        final salida = SalidaModel.fromJson(salidaData);

        // Si encontramos una salida disponible, devolverla
        if (salida.estaDisponible) {
          return salida;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Salir de una salida
  Future<void> salirDeSalida(String salidaId, String usuarioId) async {
    try {
      await supabase
          .from('salida_participantes')
          .delete()
          .eq('salida_id', salidaId)
          .eq('usuario_id', usuarioId);

      debugPrint('✅ Usuario salió de la salida');
    } catch (e) {
      throw Exception('Error al salir de la salida: $e');
    }
  }

  /// Actualizar el micro del participante
  Future<void> actualizarMicro(String salidaId, String usuarioId, String micro) async {
    try {
      await supabase
          .from('salida_participantes')
          .update({'micro': micro})
          .eq('salida_id', salidaId)
          .eq('usuario_id', usuarioId);

      debugPrint('✅ Micro actualizado');
    } catch (e) {
      throw Exception('Error al actualizar micro: $e');
    }
  }

  /// Verificar si el usuario está en una salida
  Future<bool> estaEnSalida(String salidaId, String usuarioId) async {
    try {
      final response = await supabase
          .from('salida_participantes')
          .select()
          .eq('salida_id', salidaId)
          .eq('usuario_id', usuarioId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Obtener participantes de una salida
  Future<List<SalidaParticipanteModel>> obtenerParticipantes(String salidaId) async {
    try {
      final response = await supabase
          .from('salida_participantes')
          .select('*, usuario:usuarios(*)')
          .eq('salida_id', salidaId);

      return (response as List)
          .map((json) => SalidaParticipanteModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener participantes: $e');
    }
  }

  /// Obtener número de participantes en una salida
  Future<int> obtenerNumeroParticipantes(String salidaId) async {
    try {
      final response = await supabase
          .from('salida_participantes')
          .select('id')
          .eq('salida_id', salidaId);

      return (response as List).length;
    } catch (e) {
      debugPrint('Error obteniendo número de participantes: $e');
      return 0;
    }
  }

  /// Obtener micro del usuario en una salida
  Future<String?> obtenerMicroUsuario(String salidaId, String usuarioId) async {
    try {
      final response = await supabase
          .from('salida_participantes')
          .select('micro')
          .eq('salida_id', salidaId)
          .eq('usuario_id', usuarioId)
          .maybeSingle();

      return response?['micro'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Suscribirse a cambios en participantes de una salida
  RealtimeChannel suscribirseAParticipantes(
    String salidaId,
    Function() onCambio,
  ) {
    return supabase
        .channel('salida_participantes_$salidaId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'salida_participantes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'salida_id',
            value: salidaId,
          ),
          callback: (payload) {
            debugPrint('🆕 Nuevo participante en salida');
            onCambio();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'salida_participantes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'salida_id',
            value: salidaId,
          ),
          callback: (payload) {
            debugPrint('👋 Participante salió de salida');
            onCambio();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'salida_participantes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'salida_id',
            value: salidaId,
          ),
          callback: (payload) {
            debugPrint('🔄 Participante actualizó su micro');
            onCambio();
          },
        )
        .subscribe();
  }
}