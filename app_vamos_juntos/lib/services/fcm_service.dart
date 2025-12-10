import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import '../main.dart';

// Handler para notificaciones en background/killed
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('');
  debugPrint('═══════════════════════════════════════════════');
  debugPrint('📬 FCM NOTIFICACIÓN EN BACKGROUND');
  debugPrint('   Título: ${message.notification?.title}');
  debugPrint('   Mensaje: ${message.notification?.body}');
  debugPrint('   Data: ${message.data}');
  debugPrint('═══════════════════════════════════════════════');
  debugPrint('');
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  /// Inicializar FCM
  Future<void> initialize() async {
    try {
      debugPrint('🔥 Inicializando Firebase Cloud Messaging...');

      // Solicitar permisos
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ Permisos FCM concedidos');

        // Obtener token FCM
        _fcmToken = await _messaging.getToken();
        debugPrint('🔑 FCM Token: $_fcmToken');

        if (_fcmToken != null) {
          await _guardarTokenEnSupabase(_fcmToken!);
        }

        // Listener de cambios de token
        _messaging.onTokenRefresh.listen((newToken) {
          debugPrint('🔄 Token FCM actualizado: $newToken');
          _fcmToken = newToken;
          _guardarTokenEnSupabase(newToken);
        });

        // Handler para notificaciones en foreground (app abierta)
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handler para cuando usuario toca la notificación
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

        // Registrar handler de background
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

        debugPrint('✅ FCM inicializado correctamente');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('⚠️ Permisos FCM provisionales');
      } else {
        debugPrint('❌ Permisos FCM denegados');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error inicializando FCM: $e');
      debugPrint('Stack: $stackTrace');
    }
  }

  /// Guardar token en Supabase
  Future<void> _guardarTokenEnSupabase(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);

      // Guardar en Supabase si hay usuario logueado
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        await supabase.from('usuarios').update({
          'fcm_token': token,
        }).eq('id', userId);

        debugPrint('💾 Token FCM guardado en Supabase para user: $userId');
      } else {
        debugPrint('⚠️ No hay usuario logueado, token guardado localmente');
      }
    } catch (e) {
      debugPrint('❌ Error guardando token FCM: $e');
    }
  }

  /// Actualizar token cuando usuario hace login
  Future<void> actualizarTokenAlLogin(String userId) async {
    if (_fcmToken != null) {
      try {
        await supabase.from('usuarios').update({
          'fcm_token': _fcmToken,
        }).eq('id', userId);
        debugPrint('✅ Token FCM actualizado para usuario en login');
      } catch (e) {
        debugPrint('❌ Error actualizando token en login: $e');
      }
    }
  }

  /// Limpiar token cuando usuario hace logout
  Future<void> limpiarTokenAlLogout(String userId) async {
    try {
      await supabase.from('usuarios').update({
        'fcm_token': null,
      }).eq('id', userId);
      debugPrint('🗑️ Token FCM limpiado en logout');
    } catch (e) {
      debugPrint('❌ Error limpiando token en logout: $e');
    }
  }

  /// Manejar notificación cuando app está en primer plano
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('');
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('📨 FCM NOTIFICACIÓN EN FOREGROUND');
    debugPrint('   Título: ${message.notification?.title}');
    debugPrint('   Mensaje: ${message.notification?.body}');
    debugPrint('   Data: ${message.data}');
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('');

    // Mostrar notificación local (porque FCM no muestra en foreground automáticamente)
    if (message.notification != null) {
      NotificationService().mostrarNotificacionInmediata(
        titulo: message.notification!.title ?? 'Notificación',
        mensaje: message.notification!.body ?? '',
      );
    }
  }

  /// Manejar tap en notificación
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('');
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('👆 USUARIO TOCÓ NOTIFICACIÓN FCM');
    debugPrint('   Data: ${message.data}');
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('');

    // TODO: Navegar a pantalla específica según los datos
    // Por ejemplo:
    // if (message.data['salida_id'] != null) {
    //   Navigator.push(...SalidaDetalleScreen...)
    // }
  }

  /// Suscribirse a un topic (opcional, para notificaciones masivas)
  Future<void> suscribirseATopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('✅ Suscrito a topic: $topic');
    } catch (e) {
      debugPrint('❌ Error suscribiéndose a topic: $e');
    }
  }

  /// Desuscribirse de un topic
  Future<void> desuscribirseDeTopico(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('🗑️ Desuscrito de topic: $topic');
    } catch (e) {
      debugPrint('❌ Error desuscribiéndose de topic: $e');
    }
  }
}
