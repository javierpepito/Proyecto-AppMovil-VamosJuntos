import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Callback que se ejecuta en segundo plano
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('');
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('🔄 WORKMANAGER CALLBACK INICIADO');
    debugPrint('   Task: $task');
    debugPrint('   InputData: $inputData');
    debugPrint('═══════════════════════════════════════════════');
    
    try {
      // Obtener datos guardados
      final prefs = await SharedPreferences.getInstance();
      debugPrint('📱 Obteniendo credenciales de SharedPreferences...');
      
      final userId = prefs.getString('user_id');
      final supabaseUrl = prefs.getString('supabase_url');
      final supabaseKey = prefs.getString('supabase_key');
      
      debugPrint('   user_id: ${userId ?? "NULL"}');
      debugPrint('   supabase_url: ${supabaseUrl != null ? "✓" : "NULL"}');
      debugPrint('   supabase_key: ${supabaseKey != null ? "✓" : "NULL"}');
      
      if (userId == null || supabaseUrl == null || supabaseKey == null) {
        debugPrint('❌ FALTA INFORMACIÓN: No se puede continuar');
        return Future.value(true);
      }

      // Inicializar Supabase en background
      debugPrint('🔧 Inicializando Supabase...');
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
      final supabase = Supabase.instance.client;
      debugPrint('✅ Supabase inicializado');

      // CONSULTA CORRECTA: Buscar salidas donde el usuario es participante
      debugPrint('🔍 Consultando salida_participantes para userId: $userId');
      final participaciones = await supabase
          .from('salida_participantes')
          .select('salida_id, salidas(id, hora_salida, punto_encuentro, estado)')
          .eq('usuario_id', userId);

      debugPrint('📋 Participaciones encontradas: ${participaciones.length}');

      if (participaciones.isEmpty) {
        debugPrint('ℹ️ Usuario no tiene salidas como participante');
        debugPrint('═══════════════════════════════════════════════');
        return Future.value(true);
      }

      final ahora = DateTime.now();
      debugPrint('🕐 Hora actual: ${ahora.hour}:${ahora.minute}:${ahora.second}');
      
      final notificationService = NotificationService();
      debugPrint('🔧 Inicializando NotificationService (sin permisos)...');
      // Inicializar SIN solicitar permisos (estamos en background)
      await notificationService.initialize(requestPermissions: false);
      debugPrint('✅ NotificationService listo');

      // Revisar cada participación
      int procesadas = 0;
      int notificacionesEnviadas = 0;
      for (var participacion in participaciones) {
        procesadas++;
        debugPrint('');
        debugPrint('─────── Participación $procesadas/${participaciones.length} ───────');
        
        final salidaData = participacion['salidas'];
        if (salidaData == null) {
          debugPrint('⚠️ Salida sin datos, SKIP');
          continue;
        }

        final estado = salidaData['estado'] as String?;
        if (estado != 'abierta') {
          debugPrint('⏭️ Salida no abierta (estado: $estado), SKIP');
          continue;
        }

        final salidaId = salidaData['id'];
        final horaSalida = DateTime.parse(salidaData['hora_salida']);
        final puntoEncuentro = salidaData['punto_encuentro'];
        
        final diferencia = horaSalida.difference(ahora);
        final minutos = diferencia.inMinutes;

        debugPrint('📍 ID: $salidaId');
        debugPrint('   Punto: $puntoEncuentro');
        debugPrint('   Hora: ${horaSalida.hour}:${horaSalida.minute}');
        debugPrint('   Faltan: $minutos min');

        // Verificar si ya se envió notificación
        final key10 = 'notif_10_${userId}_$salidaId';
        final keyMomento = 'notif_momento_${userId}_$salidaId';
        
        final yaEnviado10 = prefs.containsKey(key10);
        final yaEnviadoMomento = prefs.containsKey(keyMomento);
        
        debugPrint('   ¿Ya envió notif 10 min?: $yaEnviado10');
        debugPrint('   ¿Ya envió notif momento?: $yaEnviadoMomento');

        // Notificación 10 minutos antes (entre 8 y 12 minutos)
        if (minutos >= 8 && minutos <= 12) {
          if (!yaEnviado10) {
            debugPrint('   🚀 ENVIANDO notif 10 MIN...');
            await notificationService.mostrarNotificacionInmediata(
              titulo: '🚌 ¡Tu salida es en 10 minutos!',
              mensaje: 'Punto de encuentro: $puntoEncuentro',
              isBackground: true, // Indicar que estamos en background
            );
            await prefs.setBool(key10, true);
            notificacionesEnviadas++;
            debugPrint('   ✅ NOTIF 10 MIN ENVIADA');
          } else {
            debugPrint('   ⏭️ 10min ya enviado antes');
          }
        } else if (minutos > 12) {
          debugPrint('   ⏰ Aún faltan $minutos min (rango: 8-12)');
        } else if (minutos < 8 && minutos > 2) {
          debugPrint('   ⏰ Ya pasó ventana 10min (faltan $minutos)');
        }

        // Notificación al momento (entre -2 y +2 minutos)
        if (minutos >= -2 && minutos <= 2) {
          if (!yaEnviadoMomento) {
            debugPrint('   🚀 ENVIANDO notif MOMENTO...');
            await notificationService.mostrarNotificacionInmediata(
              titulo: '🚌 ¡Es hora de partir!',
              mensaje: 'Tu salida desde $puntoEncuentro está lista',
              isBackground: true, // Indicar que estamos en background
            );
            await prefs.setBool(keyMomento, true);
            notificacionesEnviadas++;
            debugPrint('   ✅ NOTIF MOMENTO ENVIADA');
          } else {
            debugPrint('   ⏭️ Momento ya enviado antes');
          }
        } else if (minutos > 2) {
          debugPrint('   ⏰ Aún no llega momento (faltan $minutos min)');
        } else if (minutos < -2) {
          debugPrint('   ⏰ Ya pasó momento (hace ${-minutos} min)');
        }

        // Limpiar notificaciones viejas (más de 3 horas pasadas)
        if (minutos < -180) {
          await prefs.remove(key10);
          await prefs.remove(keyMomento);
          debugPrint('   🗑️ Limpiadas notifs viejas');
        }
      }

      debugPrint('');
      debugPrint('═══════════════════════════════════════════════');
      debugPrint('✅ WORKMANAGER COMPLETADO');
      debugPrint('   Participaciones procesadas: $procesadas');
      debugPrint('   Notificaciones enviadas: $notificacionesEnviadas');
      debugPrint('═══════════════════════════════════════════════');
      debugPrint('');
      return Future.value(true);
    } catch (e, stackTrace) {
      debugPrint('');
      debugPrint('❌❌❌ ERROR EN WORKMANAGER ❌❌❌');
      debugPrint('Error: $e');
      debugPrint('Stack: $stackTrace');
      debugPrint('═══════════════════════════════════════════════');
      debugPrint('');
      return Future.value(false);
    }
  });
}

/// Servicio para gestionar notificaciones en segundo plano
class BackgroundNotificationService {
  static const String _taskName = 'checkNotifications';

  /// Inicializar WorkManager
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
    debugPrint('✅ WorkManager inicializado');
  }

  /// Registrar tarea periódica (cada 15 minutos)
  static Future<void> registrarTareaPeriodica() async {
    // Guardar configuración de Supabase desde config
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('supabase_url', SupabaseConfig.supabaseUrl);
    await prefs.setString('supabase_key', SupabaseConfig.supabaseAnonKey);

    await Workmanager().registerPeriodicTask(
      _taskName,
      _taskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
    debugPrint('✅ Tarea periódica registrada (cada 15 min)');
  }

  /// Guardar ID de usuario para background
  static Future<void> guardarUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    debugPrint('💾 User ID guardado para background: $userId');
  }

  /// Cancelar todas las tareas
  static Future<void> cancelarTareas() async {
    await Workmanager().cancelAll();
    debugPrint('🔕 Tareas de background canceladas');
  }

  /// Ejecutar tarea AHORA (para pruebas)
  static Future<void> ejecutarAhora() async {
    await Workmanager().registerOneOffTask(
      'test-immediate',
      _taskName,
      initialDelay: const Duration(seconds: 1),
    );
    debugPrint('🧪 Tarea de prueba ejecutándose en 1 segundo');
  }
}
