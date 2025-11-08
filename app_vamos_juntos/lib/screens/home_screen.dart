import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';
import '../widgets/barra_navegacion.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  String _userName = 'Usuario';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    try {
      final user = await _authService.obtenerPerfilUsuario();
      setState(() {
        _userName = user.nombreCompleto;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _userName = 'Usuario';
        _isLoading = false;
      });
    }
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      await _authService.cerrarSesion();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.black), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: _cerrarSesion,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Image.asset('assets/images/logo.png', width: 150, height: 150, fit: BoxFit.contain)),
                  const SizedBox(height: 20),
                  Center(
                    child: Column(
                      children: [
                        Text('Bienvenido $_userName', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 5),
                        const Text('Coordina salidas seguras con tus compañeros', style: TextStyle(fontSize: 14, color: Colors.black54)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text('Salida grupal actual', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: const Color(0xFF0D47A1), borderRadius: BorderRadius.circular(15)),
                    child: const Text('En este momento no estás dentro de ninguna salida grupal', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 30),
                  const Text('Información importante', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: const Color(0xFF00BCD4), borderRadius: BorderRadius.circular(15)),
                    child: Column(
                      children: [
                        const Text('Para poder unirte a una salida grupal debes entrar a un chat', style: TextStyle(color: Colors.white, fontSize: 15), textAlign: TextAlign.center),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF4081),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('Ir a Chats', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: const Color(0xFFFF4081), borderRadius: BorderRadius.circular(15)),
                    child: const Text('Consejo de seguridad: Antes de salir revisa tus rutas', style: TextStyle(color: Colors.white, fontSize: 15), textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 20),
                  const Center(child: Text('Versión - 1.0', style: TextStyle(color: Color(0xFF00BCD4), fontSize: 14, fontWeight: FontWeight.w500))),
                  const SizedBox(height: 20),
                ],
              ),
            ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }
}