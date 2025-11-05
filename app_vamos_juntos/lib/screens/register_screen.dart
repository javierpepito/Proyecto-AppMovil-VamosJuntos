import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _carreraController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _carreraController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        carrera: _carreraController.text,
        telefono: _telefonoController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Cuenta creada exitosamente!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0D47A1)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/logo.png', width: 120, height: 120, fit: BoxFit.contain),
                const SizedBox(height: 15),
                const Text('VAMOJUNTOS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1), letterSpacing: 1.2)),
                const SizedBox(height: 40),
                const Text('Ingresa tus datos para crearte una cuenta:', style: TextStyle(fontSize: 18, color: Colors.black)),
                const SizedBox(height: 20),
                
                TextField(controller: _carreraController, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), labelText: 'Carrera')),
                const SizedBox(height: 20),
                TextField(controller: _telefonoController, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), labelText: 'Teléfono Personal'), keyboardType: TextInputType.phone),
                const SizedBox(height: 20),
                TextField(controller: _emailController, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), labelText: 'Correo Institucional'), keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 20),
                TextField(controller: _passwordController, obscureText: true, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), labelText: 'Contraseña')),
                const SizedBox(height: 20),
                TextField(controller: _confirmPasswordController, obscureText: true, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), labelText: 'Confirmar Contraseña')),
                const SizedBox(height: 30),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      elevation: 3,
                    ),
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Crear Cuenta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}