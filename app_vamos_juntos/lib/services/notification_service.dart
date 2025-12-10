import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/notificacion_historial_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  static const String _historialKey = 'notificaciones_historial';

  /// Inicializar el servicio de notificaciones
  Future<void> initialize({bool requestPermissions = true}) async {
    if (_initialized) return;

    // Inicializar timezone
    tz.initializeTimeZones();
    // Configurar zona horaria de Chile
    tz.setLocalLocation(tz.getLocation('America/Santiago'));
    
    final now = DateTime.now();
    final tzNow = tz.TZDateTime.now(tz.local);
    debugPrint('🌍 Zona horaria configurada: ${tz.local.name}');
    debugPrint('🕐 DateTime.now(): $now');
    debugPrint('🕐 TZDateTime.now(): $tzNow');
    debugPrint('📍 Offset UTC: ${tzNow.timeZoneOffset}');

    // Configuración para Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración para iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // CRÍTICO: Crear el canal de notificaciones en Android
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        // Eliminar canal antiguo si existe y recrearlo
        try {
          await androidPlugin.deleteNotificationChannel('salidas_channel');
          debugPrint('🗑️ Canal antiguo eliminado');
        } catch (e) {
          debugPrint('ℹ️ No había canal antiguo para eliminar');
        }
        
        // Crear canal con configuración MÁXIMA
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'salidas_channel',
            'Notificaciones de Salidas',
            description: 'Notificaciones sobre tus próximas salidas grupales',
            importance: Importance.max, // MÁXIMA importancia
            playSound: true,
            enableVibration: true,
            enableLights: true,
            showBadge: true,
          ),
        );
        debugPrint('✅ Canal de notificaciones creado: salidas_channel (Importance.max)');
        
        // Verificar que el canal se creó
        final channels = await androidPlugin.getNotificationChannels();
        if (channels != null) {
          for (var channel in channels) {
            debugPrint('   Canal disponible: ${channel.id} - ${channel.name}');
          }
        }
      }
    }

    // Solicitar permisos solo si se indica (NO en background)
    if (requestPermissions) {
      await _requestPermissions();
    } else {
      debugPrint('⏭️ Permisos omitidos (modo background)');
    }

    _initialized = true;
    debugPrint('✅ NotificationService inicializado');
  }

  /// Solicitar permisos para notificaciones
  Future<void> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android 13+ requiere permiso explícito
      final status = await Permission.notification.request();
      
      if (status.isGranted) {
        debugPrint('✅ Permiso de notificaciones concedido');
        
        // Verificar y solicitar permiso para alarmas exactas (Android 12+)
        final alarmaStatus = await Permission.scheduleExactAlarm.status;
        debugPrint('🔔 Estado alarmas exactas: $alarmaStatus');
        
        if (!alarmaStatus.isGranted) {
          debugPrint('⚠️ Alarmas exactas NO habilitadas');
          // En Android 12+, el usuario debe habilitarlo manualmente en configuración
          await Permission.scheduleExactAlarm.request();
          
          // Verificar nuevamente
          final nuevoEstado = await Permission.scheduleExactAlarm.status;
          if (!nuevoEstado.isGranted) {
            debugPrint('❌ ¡IMPORTANTE! Debes habilitar "Alarmas y recordatorios" manualmente:');
            debugPrint('   Configuración → Aplicaciones → app_vamos_juntos → Alarmas y recordatorios');
          } else {
            debugPrint('✅ Alarmas exactas habilitadas');
          }
        } else {
          debugPrint('✅ Alarmas exactas ya habilitadas');
        }
      } else {
        debugPrint('⚠️ Permiso de notificaciones denegado');
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  /// Programar notificaciones para una salida
  /// - Notificación 10 minutos antes
  /// - Notificación al momento de la salida
  Future<void> programarNotificacionesSalida({
    required String salidaId,
    required DateTime horaSalida,
    required String puntoEncuentro,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      // Convertir hora de salida a TZDateTime (zona horaria de Chile)
      final tzHoraSalida = tz.TZDateTime.from(horaSalida, tz.local);
      final ahora = tz.TZDateTime.now(tz.local);

      debugPrint('🕐 HORA ACTUAL (Chile): $ahora');
      debugPrint('🕐 HORA SALIDA (Chile): $tzHoraSalida');
      debugPrint('🕐 HORA SALIDA (Original): $horaSalida');

      // Notificación 10 minutos antes
      final notificacion10Min = tzHoraSalida.subtract(const Duration(minutes: 10));
      debugPrint('🕐 NOTIF 10 MIN PARA: $notificacion10Min');
      debugPrint('⏰ ¿10 min es futuro? ${notificacion10Min.isAfter(ahora)}');
      
      if (notificacion10Min.isAfter(ahora)) {
        final titulo10 = '🚌 ¡Tu salida es en 10 minutos!';
        final body10 = 'Punto de encuentro: $puntoEncuentro a las ${_formatHora(horaSalida)}';
        
        await _scheduleNotification(
          id: _getNotificationId(salidaId, 10),
          title: titulo10,
          body: body10,
          scheduledDate: notificacion10Min,
          salidaId: salidaId,
          puntoEncuentro: puntoEncuentro,
          tipo: '10min',
        );
        debugPrint('✅ Notificación 10 min programada para: $notificacion10Min');
      } else {
        debugPrint('⚠️ NO se programó notif 10 min (ya pasó la hora)');
      }

      // Notificación al momento de la salida
      debugPrint('⏰ ¿Momento es futuro? ${tzHoraSalida.isAfter(ahora)}');
      
      if (tzHoraSalida.isAfter(ahora)) {
        final tituloMomento = '🚌 ¡Es hora de partir!';
        final bodyMomento = 'Tu salida desde $puntoEncuentro está lista. ¡Nos vemos!';
        
        await _scheduleNotification(
          id: _getNotificationId(salidaId, 0),
          title: tituloMomento,
          body: bodyMomento,
          scheduledDate: tzHoraSalida,
          salidaId: salidaId,
          puntoEncuentro: puntoEncuentro,
          tipo: 'momento',
        );
        debugPrint('✅ Notificación momento salida programada para: $tzHoraSalida');
      } else {
        debugPrint('⚠️ NO se programó notif momento (ya pasó la hora)');
      }

      // NOTIFICACIÓN DE PRUEBA INMEDIATA (para verificar que funciona)
      final notifPrueba = ahora.add(const Duration(seconds: 5));
      debugPrint('🧪 Programando notificación de PRUEBA en 5 segundos: $notifPrueba');
      await _scheduleNotification(
        id: _getNotificationId(salidaId, 999),
        title: '🧪 Prueba de Notificación',
        body: 'Si ves esto, las notificaciones funcionan. Salida: $puntoEncuentro',
        scheduledDate: notifPrueba,
        salidaId: salidaId,
        puntoEncuentro: puntoEncuentro,
        tipo: 'prueba',
      );
    } catch (e) {
      debugPrint('❌ Error al programar notificaciones: $e');
    }
  }

  /// Programar una notificación específica
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    String? salidaId,
    String? puntoEncuentro,
    String? tipo,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'salidas_channel',
      'Notificaciones de Salidas',
      channelDescription: 'Notificaciones sobre tus próximas salidas grupales',
      importance: Importance.max, // MÁXIMA importancia
      priority: Priority.max, // MÁXIMA prioridad
      playSound: true,
      enableVibration: true,
      enableLights: true,
      showWhen: true,
      ticker: 'Notificación de Salida', // Ayuda en accesibilidad
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Verificar que la hora sea futura
    final ahora = tz.TZDateTime.now(tz.local);
    final diferencia = scheduledDate.difference(ahora);
    
    debugPrint('📢 ========== PROGRAMANDO NOTIFICACIÓN ==========');
    debugPrint('   ID: $id');
    debugPrint('   Título: $title');
    debugPrint('   Cuerpo: $body');
    debugPrint('   Hora AHORA (TZ): $ahora');
    debugPrint('   Hora PROGRAMADA (TZ): $scheduledDate');
    debugPrint('   Diferencia: ${diferencia.inSeconds}s (${diferencia.inMinutes}m)');
    debugPrint('   ¿Es futuro?: ${scheduledDate.isAfter(ahora)}');
    debugPrint('   Modo: AndroidScheduleMode.exactAllowWhileIdle');
    
    if (scheduledDate.isBefore(ahora) || scheduledDate.isAtSameMomentAs(ahora)) {
      debugPrint('❌ ERROR: La hora programada ya pasó o es ahora mismo');
      debugPrint('   No se programará la notificación');
      return;
    }

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      debugPrint('✅ zonedSchedule() ejecutado SIN ERRORES');
      debugPrint('   La notificación debería aparecer en ${diferencia.inSeconds} segundos');
      
      // Verificar que se programó
      final pendingNotifications = await _notifications.pendingNotificationRequests();
      final programada = pendingNotifications.any((n) => n.id == id);
      debugPrint('   ¿Está en pendientes?: ${programada ? "SÍ ✅" : "NO ❌"}');
      debugPrint('   Total pendientes: ${pendingNotifications.length}');
      
      if (programada) {
        debugPrint('   🎯 NOTIFICACIÓN CONFIRMADA EN COLA');
      } else {
        debugPrint('   ⚠️ ADVERTENCIA: No aparece en pendientes');
      }
    } catch (e, stack) {
      debugPrint('❌ ERROR al llamar zonedSchedule(): $e');
      debugPrint('Stack: $stack');
    }
    debugPrint('================================================');

    // Guardar en historial (esto es para que el usuario vea que se programó)
    // Nota: Esto significa que aparecerá en el historial antes de que se dispare
    final fechaHistorial = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      scheduledDate.hour,
      scheduledDate.minute,
      scheduledDate.second,
    );
    
    await _guardarEnHistorial(
      titulo: title,
      mensaje: body,
      fecha: fechaHistorial,
      tipo: tipo ?? 'general',
      salidaId: salidaId,
      puntoEncuentro: puntoEncuentro,
    );
    
    debugPrint('💾 Guardado en historial para referencia');
  }

  /// Cancelar notificaciones de una salida específica
  Future<void> cancelarNotificacionesSalida(String salidaId) async {
    try {
      await _notifications.cancel(_getNotificationId(salidaId, 10));
      await _notifications.cancel(_getNotificationId(salidaId, 0));
      await _notifications.cancel(_getNotificationId(salidaId, 999)); // Prueba
      debugPrint('🔕 Notificaciones canceladas para salida: $salidaId');
    } catch (e) {
      debugPrint('❌ Error al cancelar notificaciones: $e');
    }
  }

  /// Cancelar todas las notificaciones
  Future<void> cancelarTodasLasNotificaciones() async {
    await _notifications.cancelAll();
    debugPrint('🔕 Todas las notificaciones canceladas');
  }

  /// Mostrar notificación INMEDIATA (sin programar) - Para testing
  Future<void> mostrarNotificacionInmediata({
    required String titulo,
    required String mensaje,
    bool isBackground = false, // Nuevo parámetro
  }) async {
    if (!_initialized) {
      // En background NO solicitar permisos
      await initialize(requestPermissions: !isBackground);
    }

    const androidDetails = AndroidNotificationDetails(
      'salidas_channel',
      'Notificaciones de Salidas',
      channelDescription: 'Notificaciones sobre tus próximas salidas grupales',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999999, // ID único para pruebas
      titulo,
      mensaje,
      details,
    );
    
    debugPrint('✅ Notificación INMEDIATA mostrada: $titulo');
    
    await _guardarEnHistorial(
      titulo: titulo,
      mensaje: mensaje,
      fecha: DateTime.now(),
      tipo: 'inmediata',
    );
  }

  /// MÉTODO DE PRUEBA: Verificar notificaciones pendientes
  Future<void> verNotificacionesPendientes() async {
    final pending = await _notifications.pendingNotificationRequests();
    debugPrint('📋 ========== NOTIFICACIONES PENDIENTES ==========');
    debugPrint('   Total: ${pending.length}');
    for (var p in pending) {
      debugPrint('   - ID: ${p.id}');
      debugPrint('     Título: ${p.title}');
      debugPrint('     Cuerpo: ${p.body}');
    }
    debugPrint('==================================================');
  }

  /// Generar ID único para notificaciones basado en salidaId y tipo
  int _getNotificationId(String salidaId, int minutosBefore) {
    // Usar hash del salidaId + offset para distinguir entre notificaciones
    final hash = salidaId.hashCode & 0x7FFFFFFF; // Mantener positivo
    return hash + minutosBefore;
  }

  /// Formatear hora HH:MM
  String _formatHora(DateTime hora) {
    return '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
  }

  /// Callback cuando se toca una notificación
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Notificación tocada: ${response.payload}');
    // Aquí puedes navegar a una pantalla específica si lo necesitas
  }

  /// Verificar si las notificaciones están habilitadas
  Future<bool> notificacionesHabilitadas() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.status;
      return status.isGranted;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions();
      return result ?? false;
    }
    return false;
  }

  /// Verificar si las alarmas exactas están habilitadas (Android 12+)
  Future<bool> alarmasExactasHabilitadas() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.scheduleExactAlarm.status;
      return status.isGranted;
    }
    return true; // iOS no necesita este permiso
  }

  /// Abrir configuración de la app para habilitar alarmas exactas
  Future<void> abrirConfiguracionAlarmas() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await openAppSettings();
    }
  }

  // ==================== GESTIÓN DE HISTORIAL ====================

  /// Guardar notificación en el historial
  Future<void> _guardarEnHistorial({
    required String titulo,
    required String mensaje,
    required DateTime fecha,
    required String tipo,
    String? salidaId,
    String? puntoEncuentro,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historial = await obtenerHistorial();

      final nuevaNotificacion = NotificacionHistorialModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        titulo: titulo,
        mensaje: mensaje,
        fecha: fecha,
        tipo: tipo,
        salidaId: salidaId,
        puntoEncuentro: puntoEncuentro,
        leida: false,
      );

      historial.insert(0, nuevaNotificacion);

      // Mantener solo las últimas 50 notificaciones
      if (historial.length > 50) {
        historial.removeRange(50, historial.length);
      }

      final jsonList = historial.map((n) => n.toJson()).toList();
      await prefs.setString(_historialKey, jsonEncode(jsonList));
      
      debugPrint('💾 Notificación guardada en historial');
    } catch (e) {
      debugPrint('❌ Error al guardar notificación en historial: $e');
    }
  }

  /// Obtener historial de notificaciones
  Future<List<NotificacionHistorialModel>> obtenerHistorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_historialKey);
      
      if (jsonString == null) return [];

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((json) => NotificacionHistorialModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error al obtener historial: $e');
      return [];
    }
  }

  /// Marcar notificación como leída
  Future<void> marcarComoLeida(String notificacionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historial = await obtenerHistorial();

      final index = historial.indexWhere((n) => n.id == notificacionId);
      if (index != -1) {
        historial[index] = historial[index].copyWith(leida: true);
        
        final jsonList = historial.map((n) => n.toJson()).toList();
        await prefs.setString(_historialKey, jsonEncode(jsonList));
      }
    } catch (e) {
      debugPrint('❌ Error al marcar como leída: $e');
    }
  }

  /// Marcar todas como leídas
  Future<void> marcarTodasComoLeidas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historial = await obtenerHistorial();

      final historialActualizado = historial
          .map((n) => n.copyWith(leida: true))
          .toList();

      final jsonList = historialActualizado.map((n) => n.toJson()).toList();
      await prefs.setString(_historialKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('❌ Error al marcar todas como leídas: $e');
    }
  }

  /// Limpiar historial
  Future<void> limpiarHistorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historialKey);
      debugPrint('🗑️ Historial de notificaciones limpiado');
    } catch (e) {
      debugPrint('❌ Error al limpiar historial: $e');
    }
  }

  /// Obtener número de notificaciones no leídas
  Future<int> obtenerNoLeidas() async {
    final historial = await obtenerHistorial();
    return historial.where((n) => !n.leida).length;
  }
}
