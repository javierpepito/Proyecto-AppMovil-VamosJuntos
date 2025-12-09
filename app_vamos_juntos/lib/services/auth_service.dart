import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? get usuarioActual => supabase.auth.currentUser;
  bool get estaAutenticado => usuarioActual != null;

  /// Iniciar sesión
  Future<UserModel> iniciarSesion({
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

      // Obtener datos del usuario desde la tabla 'usuarios'
      final usuarioData = await supabase
          .from('usuarios')
          .select()
          .eq('id', response.user!.id)
          .single();

      return UserModel.fromJson(usuarioData);
    } on AuthException catch (e) {
      // Mensajes de error en español
      if (e.message.contains('Invalid login credentials')) {
        throw Exception('Correo o contraseña incorrectos');
      } else if (e.message.contains('Email not confirmed')) {
        throw Exception('Debes confirmar tu correo electrónico');
      } else {
        throw Exception('Error de autenticación: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  /// Registrar nuevo usuario
  Future<UserModel> registrarUsuario({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
    required String carrera,
    required String telefono,
  }) async {
    try {
      // Validaciones
      if (nombre.trim().isEmpty) {
        throw Exception('El nombre es obligatorio');
      }
      if (apellido.trim().isEmpty) {
        throw Exception('El apellido es obligatorio');
      }
      if (password.length < 6) {
        throw Exception('La contraseña debe tener al menos 6 caracteres');
      }

      // Validar dominio institucional
      final emailTrimmed = email.trim().toLowerCase();
      if (!emailTrimmed.endsWith('@inacapmail.cl') && !emailTrimmed.endsWith('@inacap.cl')) {
        throw Exception('Debes usar un correo institucional (@inacapmail.cl o @inacap.cl)');
      }

      // Verificar si el email pertenece a un profesor
      final profesorData = await supabase
          .from('profesores')
          .select('email')
          .eq('email', emailTrimmed)
          .maybeSingle();

      final esProfesor = profesorData != null;
      final rolUsuario = esProfesor ? 'profesor' : 'estudiante';

      // Crear usuario en Auth
      final response = await supabase.auth.signUp(
        email: emailTrimmed,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Error al crear usuario en el sistema de autenticación');
      }

      // Preparar datos del perfil
      final usuarioData = {
        'id': response.user!.id,
        'nombre': nombre.trim(),
        'apellido': apellido.trim(),
        'carrera': carrera.trim().isNotEmpty ? carrera.trim() : null,
        'telefono_personal': telefono.trim().isNotEmpty ? telefono.trim() : null,
        'email': emailTrimmed,
        'rol': rolUsuario,
      };

      // Insertar en la tabla 'usuarios'
      await supabase.from('usuarios').insert(usuarioData);

      return UserModel.fromJson(usuarioData);
    } on AuthException catch (e) {
      // Mensajes de error en español
      if (e.message.contains('already registered')) {
        throw Exception('Este correo ya está registrado');
      } else if (e.message.contains('invalid email')) {
        throw Exception('El formato del correo no es válido');
      } else {
        throw Exception('Error de registro: ${e.message}');
      }
    } on PostgrestException catch (e) {
      // Errores de base de datos
      if (e.code == '23505') {
        throw Exception('Este correo ya está registrado');
      } else {
        throw Exception('Error en la base de datos: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  /// Obtener perfil del usuario actual
  Future<UserModel> obtenerPerfilUsuario() async {
    try {
      if (usuarioActual == null) {
        throw Exception('No hay usuario autenticado');
      }

      final data = await supabase
          .from('usuarios')
          .select()
          .eq('id', usuarioActual!.id)
          .single();

      return UserModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener perfil: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  /// Actualizar perfil del usuario
Future<void> actualizarPerfil({
  String? nombre,
  String? apellido,
  String? carrera,
  String? telefonoPersonal,
}) async {
  try {
    if (usuarioActual == null) {
      throw Exception('No hay usuario autenticado');
    }

    final datosActualizar = <String, dynamic>{};
    
    if (nombre != null && nombre.trim().isNotEmpty) {
      datosActualizar['nombre'] = nombre.trim();
    }
    if (apellido != null && apellido.trim().isNotEmpty) {
      datosActualizar['apellido'] = apellido.trim();
    }
    if (carrera != null) {
      datosActualizar['carrera'] = carrera.trim().isNotEmpty ? carrera.trim() : null;
    }
    if (telefonoPersonal != null) {
      datosActualizar['telefono_personal'] = telefonoPersonal.trim().isNotEmpty ? telefonoPersonal.trim() : null;
    }

    if (datosActualizar.isEmpty) {
      throw Exception('No hay datos para actualizar');
    }

    await supabase
        .from('usuarios')
        .update(datosActualizar)
        .eq('id', usuarioActual!.id);
  } catch (e) {
    throw Exception('Error al actualizar perfil: $e');
  }
}

  /// Cerrar sesión
  Future<void> cerrarSesion() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  /// Verificar si el email ya está registrado
  Future<bool> emailYaRegistrado(String email) async {
    try {
      final data = await supabase
          .from('usuarios')
          .select('id')
          .eq('email', email.trim())
          .maybeSingle();

      return data != null;
    } catch (e) {
      return false;
    }
  }
}