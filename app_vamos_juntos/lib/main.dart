import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/chat_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Inicializar sistema de chats
  await ChatService().inicializarSistema();
  
  // Inicializar servicio de notificaciones
  await NotificationService().initialize();
  
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
      home: _buildHome(),
    );
  }

  /// Verifica si hay sesión activa y redirige apropiadamente
  Widget _buildHome() {
    final session = supabase.auth.currentSession;
    if (session != null) {
      return const HomeScreen();
    }
    return const LoginScreen();
  }
}