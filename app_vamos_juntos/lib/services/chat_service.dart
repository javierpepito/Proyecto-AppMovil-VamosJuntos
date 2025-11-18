import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../main.dart';
import '../models/chat_model.dart';
import '../models/mensaje.model.dart';
import '../models/salida_model.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  DateTime _getChileTime() {
    return DateTime.now().toUtc().subtract(const Duration(hours: 3));
  }

  String _getChileDateString() {
    final chileTime = _getChileTime();
    return '${chileTime.year}-${chileTime.month.toString().padLeft(2, '0')}-${chileTime.day.toString().padLeft(2, '0')}';
  }

  /// Inicializar sistema de chats (llamar al iniciar la app)
  Future<void> inicializarSistema() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ultimaEjecucion = prefs.getString('ultima_inicializacion_chats');
      final hoy = _getChileDateString(); 
      
      debugPrint('📅 Fecha de Chile: $hoy');
      debugPrint('📅 Última ejecución: $ultimaEjecucion');
      
      if (ultimaEjecucion == hoy) {
        debugPrint('✅ Sistema de chats ya inicializado hoy');
        // Aunque ya se inicializó, actualizar estados
        await _actualizarEstadosVencidos();
        return;
      }
      
      debugPrint('🔄 Inicializando sistema de chats...');
      
      await cerrarChatsAntiguos();
      await generarChatsDelDia();
      await generarSalidasParaTodosLosChats();
      
      await prefs.setString('ultima_inicializacion_chats', hoy);
      
      debugPrint('✅ Sistema de chats inicializado correctamente');
    } catch (e) {
      debugPrint('⚠️ Error inicializando sistema: $e');
    }
  }

  /// Actualizar estados de chats y salidas vencidos
  Future<void> _actualizarEstadosVencidos() async {
    try {
      final ahoraChile = _getChileTime();
      final horaActual = '${ahoraChile.hour.toString().padLeft(2, '0')}:${ahoraChile.minute.toString().padLeft(2, '0')}:00';
      final fechaHoy = _getChileDateString();
      
      debugPrint('🕐 Actualizando estados - Hora Chile: ${ahoraChile.toString()}');
      
      // Cerrar chats cuya hora de término ya pasó
      await supabase
          .from('chats')
          .update({'estado': 'finalizado'})
          .eq('fecha', fechaHoy)
          .eq('estado', 'activo')
          .lt('hora_termino', horaActual);
      
      // Cerrar salidas que ya pasaron
      await supabase
          .from('salidas')
          .update({'estado': 'cerrada'})
          .eq('estado', 'abierta')
          .lt('hora_salida', ahoraChile.toIso8601String());
      
      debugPrint('✅ Estados actualizados');
    } catch (e) {
      debugPrint('⚠️ Error actualizando estados: $e');
    }
  }

  /// Generar chats del día actual
  Future<void> generarChatsDelDia() async {
    try {
      debugPrint('📞 Llamando a generar_chats_del_dia()...');
      await supabase.rpc('generar_chats_del_dia');
      debugPrint('✅ Chats del día generados');
    } catch (e) {
      debugPrint('⚠️ Error generando chats: $e');
      // Imprimir el error completo para debugging
      if (e is PostgrestException) {
        debugPrint('   Código: ${e.code}');
        debugPrint('   Mensaje: ${e.message}');
        debugPrint('   Detalles: ${e.details}');
      }
    }
  }

  /// Cerrar chats antiguos
  Future<void> cerrarChatsAntiguos() async {
    try {
      debugPrint('📞 Llamando a cerrar_chats_antiguos()...');
      await supabase.rpc('cerrar_chats_antiguos');
      debugPrint('✅ Chats antiguos cerrados');
    } catch (e) {
      debugPrint('⚠️ Error cerrando chats antiguos: $e');
    }
  }

  /// Generar salidas para todos los chats activos de hoy
  Future<void> generarSalidasParaTodosLosChats() async {
    try {
      final fechaStr = _getChileDateString(); // ⭐ CAMBIO
      
      debugPrint('🔍 Buscando chats del día: $fechaStr');
      
      final response = await supabase
          .from('chats')
          .select('id')
          .eq('fecha', fechaStr)
          .eq('estado', 'activo');

      final chats = response as List;
      
      debugPrint('📊 Chats encontrados: ${chats.length}');

      for (var chat in chats) {
        try {
          final salidasResponse = await supabase
              .from('salidas')
              .select('id')
              .eq('chat_id', chat['id'])
              .limit(1);

          final salidasExistentes = salidasResponse as List;

          if (salidasExistentes.isEmpty) {
            debugPrint('   Generando salidas para chat: ${chat['id']}');
            await supabase.rpc('generar_salidas_para_chat', params: {
              'chat_id_param': chat['id'],
            });
          } else {
            debugPrint('   Chat ${chat['id']} ya tiene salidas');
          }
        } catch (e) {
          debugPrint('⚠️ Error generando salidas para chat ${chat['id']}: $e');
        }
      }
      
      debugPrint('✅ Salidas generadas para todos los chats');
    } catch (e) {
      debugPrint('⚠️ Error generando salidas: $e');
    }
  }

  /// Obtener chats con filtrado inteligente
  Future<List<ChatModel>> obtenerChats({
    String? paradero,
    DateTime? fecha,
    String? estado,
    bool soloDisponibles = true,
  }) async {
    try {
      // Actualizar estados antes de obtener
      await _actualizarEstadosVencidos();
      
      var query = supabase.from('chats').select();

      if (paradero != null && paradero.isNotEmpty) {
        query = query.eq('paradero', paradero);
      }
      
      if (fecha != null) {
        final fechaStr = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
        query = query.eq('fecha', fechaStr);
      } else {
        final fechaStr = _getChileDateString();
        query = query.eq('fecha', fechaStr);
      }

      if (estado != null) {
        query = query.eq('estado', estado);
      } else {
        query = query.eq('estado', 'activo');
      }

      final response = await query.order('hora_inicio', ascending: true);
      
      List<ChatModel> chats = (response as List)
          .map((json) => ChatModel.fromJson(json))
          .toList();

      // Filtrar solo disponibles si se solicita
      if (soloDisponibles) {
        chats = chats.where((chat) => chat.estaDisponible).toList();
      }

      return chats;
    } catch (e) {
      throw Exception('Error al obtener chats: $e');
    }
  }

  // ... resto de métodos sin cambios ...
  
  /// Obtener detalles de un chat específico
  Future<ChatModel> obtenerChat(String chatId) async {
    try {
      final response = await supabase
          .from('chats')
          .select()
          .eq('id', chatId)
          .single();

      return ChatModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener chat: $e');
    }
  }

  /// Validar acceso a un chat
  Future<bool> puedeAccederAlChat(String chatId) async {
    try {
      final chat = await obtenerChat(chatId);
      return chat.estaDisponible;
    } catch (e) {
      return false;
    }
  }

  /// Unirse a un chat
  Future<void> unirseAChat(String chatId, String usuarioId) async {
    try {
      final puedeAcceder = await puedeAccederAlChat(chatId);
      if (!puedeAcceder) {
        throw Exception('Este chat ya no está disponible');
      }

      await supabase.from('chat_participantes').insert({
        'chat_id': chatId,
        'usuario_id': usuarioId,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        return;
      }
      throw Exception('Error al unirse al chat: ${e.message}');
    } catch (e) {
      throw Exception('Error al unirse al chat: $e');
    }
  }

  /// Verificar si el usuario está en el chat
  Future<bool> estaEnChat(String chatId, String usuarioId) async {
    try {
      final response = await supabase
          .from('chat_participantes')
          .select()
          .eq('chat_id', chatId)
          .eq('usuario_id', usuarioId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Obtener número de participantes ACTIVOS (con salidas activas) en un chat
  Future<int> obtenerNumeroParticipantes(String chatId) async {
    try {
      final response = await supabase
          .rpc('contar_participantes_activos_chat', params: {
            'chat_id_param': chatId,
          });

      return response as int? ?? 0;
    } catch (e) {
      debugPrint('Error obteniendo participantes activos: $e');
      return 0;
    }
  }

  /// Enviar mensaje
  Future<MensajeModel> enviarMensaje({
    required String chatId,
    required String usuarioId,
    required String contenido,
  }) async {
    try {
      final puedeAcceder = await puedeAccederAlChat(chatId);
      if (!puedeAcceder) {
        throw Exception('Este chat ya no está disponible para enviar mensajes');
      }

      final estaUnido = await estaEnChat(chatId, usuarioId);
      if (!estaUnido) {
        await unirseAChat(chatId, usuarioId);
      }

      final response = await supabase
          .from('mensajes')
          .insert({
            'chat_id': chatId,
            'usuario_id': usuarioId,
            'contenido': contenido.trim(),
          })
          .select()
          .single();

      return MensajeModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al enviar mensaje: $e');
    }
  }

  /// Obtener mensajes de un chat
  Future<List<MensajeModel>> obtenerMensajes(String chatId) async {
    try {
      final response = await supabase
          .from('mensajes')
          .select('*, usuario:usuarios(*)')
          .eq('chat_id', chatId)
          .order('hora_enviado', ascending: true);

      return (response as List).map((json) => MensajeModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener mensajes: $e');
    }
  }

  /// Suscribirse a mensajes en tiempo real
  RealtimeChannel suscribirseAMensajes(String chatId, Function(MensajeModel) onMensaje) {
    return supabase
        .channel('mensajes_$chatId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mensajes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (payload) async {
            try {
              final mensajeCompleto = await supabase
                  .from('mensajes')
                  .select('*, usuario:usuarios(*)')
                  .eq('id', payload.newRecord['id'])
                  .single();
              
              onMensaje(MensajeModel.fromJson(mensajeCompleto));
            } catch (e) {
              debugPrint('Error obteniendo mensaje completo: $e');
            }
          },
        )
        .subscribe();
  }

  /// Suscribirse a cambios en participantes de un chat
  RealtimeChannel suscribirseAParticipantesChat(
    String chatId,
    Function() onCambio,
  ) {
    return supabase
        .channel('chat_participantes_$chatId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_participantes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (payload) {
            debugPrint('🆕 Nuevo participante en chat');
            onCambio();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'chat_participantes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (payload) {
            debugPrint('👋 Participante salió del chat');
            onCambio();
          },
        )
        .subscribe();
  }

  /// Obtener salidas de un chat (solo disponibles)
  Future<List<SalidaModel>> obtenerSalidasDeChat(String chatId, {bool soloDisponibles = true}) async {
    try {
      await _actualizarEstadosVencidos();
      
      final response = await supabase
          .from('salidas')
          .select()
          .eq('chat_id', chatId)
          .order('hora_salida', ascending: true);

      List<SalidaModel> salidas = (response as List)
          .map((json) => SalidaModel.fromJson(json))
          .toList();

      if (soloDisponibles) {
        salidas = salidas.where((salida) => salida.estaDisponible).toList();
      }

      return salidas;
    } catch (e) {
      throw Exception('Error al obtener salidas: $e');
    }
  }
}