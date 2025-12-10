import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/background_notification_service.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import '../utils/validators.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  // Toggle de visibilidad
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (_emailController.text.trim().isEmpty) {
      _mostrarError('Por favor ingresa tu correo');
      return;
    }
    if (_passwordController.text.isEmpty) {
      _mostrarError('Por favor ingresa tu contraseña');
      return;
    }

    // Validación de contraseña fuerte
    final pwdError = Validators.passwordStrong(_passwordController.text, minLen: 12);
    if (pwdError != null) {
      _mostrarError(pwdError);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.iniciarSesion(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Guardar user ID y registrar tarea de background
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        await BackgroundNotificationService.guardarUserId(userId);
        await BackgroundNotificationService.registrarTareaPeriodica();
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        _mostrarError(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/logo.png', width: 180, height: 180, fit: BoxFit.contain),
                const SizedBox(height: 20),
                const Text('VAMOJUNTOS', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1), letterSpacing: 1.2)),
                const SizedBox(height: 50),

                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    labelText: 'Correo Institucional',
                    prefixIcon: const Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 20),

                // Contraseña con botón de mostrar/ocultar
                TextField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock),
                    helperText: 'Debe tener al menos 12 caracteres, una mayúscula, un número y un símbolo',
                    suffixIcon: IconButton(
                      icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  enabled: !_isLoading,
                  onSubmitted: (_) => _handleSignIn(),
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      elevation: 3,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Iniciar Sesión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 15),

                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                      children: [
                        const TextSpan(text: 'No tienes una cuenta creada\n'),
                        TextSpan(text: 'Haz click aquí', style: TextStyle(color: Colors.blue[700], decoration: TextDecoration.underline)),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}