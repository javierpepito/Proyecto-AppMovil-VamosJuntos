import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/perfil_screen.dart';
import '../screens/info_paraderos_screen.dart';
import '../screens/info_encuentro_screen.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  void _onItemTapped(BuildContext context, int index) {
    // Si ya estamos en la pantalla actual, no hacer nada
    if (index == currentIndex) return;

    // Navegar según el índice seleccionado
    switch (index) {
      case 0:
        // Botón Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        break;
      case 1:
        // Botón Chat (por implementar)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat en desarrollo')),
        );
        break;
      case 2:
        // Botón Ubicación - Paraderos
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => InfoParaderosPage()),
        );
        break;
      case 3:
        // Botón Información - Punto de Encuentro
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const InfoPuntoEncuentroPage()),
        );
        break;
      case 4:
        // Botón Perfil
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PerfilPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF0D47A1),
      unselectedItemColor: Colors.grey,
      currentIndex: currentIndex,
      onTap: (index) => _onItemTapped(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.location_on_outlined),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.info_outline),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: '',
        ),
      ],
    );
  }
}