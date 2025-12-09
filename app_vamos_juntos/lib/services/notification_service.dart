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
  Future<void> initialize() async {
    if (_initialized) return;

    // Inicializar timezone
    tz.initializeTimeZones();
    // Configurar zona horaria de Chile
    tz.setLocalLocation(tz.getLocation('America/Santiago'));

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

    // Solicitar permisos
    await _requestPermissions();

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
        
        // Solicitar permiso para alarmas exactas (Android 12+)
        if (await Permission.scheduleExactAlarm.isDenied) {
          await Permission.scheduleExactAlarm.request();
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

      // Notificación 10 minutos antes
      final notificacion10Min = tzHoraSalida.subtract(const Duration(minutes: 10));
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
        debugPrint('📅 Notificación 10 min programada para: $notificacion10Min');
      }

      // Notificación al momento de la salida
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
        debugPrint('📅 Notificación momento salida programada para: $tzHoraSalida');
      }
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

    // Guardar en historial cuando se programa
    await _guardarEnHistorial(
      titulo: title,
      mensaje: body,
      fecha: scheduledDate.toLocal(),
      tipo: tipo ?? 'general',
      salidaId: salidaId,
      puntoEncuentro: puntoEncuentro,
    );
  }

  /// Cancelar notificaciones de una salida específica
  Future<void> cancelarNotificacionesSalida(String salidaId) async {
    try {
      await _notifications.cancel(_getNotificationId(salidaId, 10));
      await _notifications.cancel(_getNotificationId(salidaId, 0));
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
