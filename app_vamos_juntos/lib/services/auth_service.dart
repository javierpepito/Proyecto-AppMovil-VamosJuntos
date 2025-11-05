import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? get currentUser => supabase.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  // Iniciar sesión
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        throw Exception('Error al iniciar sesión');
      }

      final profileData = await supabase
          .from('profiles')
          .select()
          .eq('id', response.user!.id)
          .single();

      return UserModel.fromJson(profileData);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  // Registrar usuario
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String carrera,
    required String telefono,
  }) async {
    try {
      if (password.length < 6) {
        throw Exception('La contraseña debe tener al menos 6 caracteres');
      }

      final response = await supabase.auth.signUp(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        throw Exception('Error al crear usuario');
      }

      final profileData = {
        'id': response.user!.id,
        'carrera': carrera.trim(),
        'telefono_personal': telefono.trim(),
        'email': email.trim(),
      };

      await supabase.from('profiles').insert(profileData);

      return UserModel.fromJson(profileData);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  // Obtener perfil del usuario
  Future<UserModel> getUserProfile() async {
    try {
      if (currentUser == null) {
        throw Exception('No hay usuario autenticado');
      }

      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .single();

      return UserModel.fromJson(data);
    } catch (e) {
      throw Exception('Error al obtener perfil: $e');
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}