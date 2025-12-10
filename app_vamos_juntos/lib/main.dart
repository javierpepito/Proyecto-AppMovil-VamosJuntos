import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'config/supabase_config.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/chat_service.dart';
import 'services/notification_service.dart';
import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase PRIMERO
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Inicializar Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Inicializar sistema de chats
  await ChatService().inicializarSistema();
  
  // Inicializar servicio de notificaciones locales
  await NotificationService().initialize();
  
  // Inicializar FCM (Firebase Cloud Messaging) - Notificaciones con app cerrada
  await FCMService().initialize();
  
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VAMOJUNTOS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthWrapper(), // Verificar sesión
    );
  }
}

/// Widget para verificar si hay sesión activa
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _verificarSesion();
  }

  Future<void> _verificarSesion() async {
    // Si hay sesión activa, actualizar token FCM
    final session = supabase.auth.currentSession;
    if (session != null) {
      final userId = session.user.id;
      await FCMService().actualizarTokenAlLogin(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    // StreamBuilder escucha cambios de autenticación
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Mientras carga, mostrar splash
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Si hay sesión activa, ir a Home
        final session = snapshot.hasData ? snapshot.data!.session : null;
        if (session != null) {
          return const HomeScreen();
        }

        // Si no hay sesión, ir a Login
        return const LoginScreen();
      },
    );
  }
}