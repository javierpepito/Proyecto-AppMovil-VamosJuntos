import 'package:flutter/material.dart';
import '../widgets/barra_navegacion.dart';

class InfoPuntoEncuentroPage extends StatelessWidget {
  const InfoPuntoEncuentroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Información del punto de encuentro',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w400),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Sección Hall Principal ----
            const Text(
              'Hall Principal',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Este es el hall principal del INACAP, donde los usuarios pueden esperar y reunirse antes de irse del instituto. El hall cuenta con áreas de descanso, señalización clara y acceso a servicios básicos para la comodidad de los usuarios.',
              style: TextStyle(fontSize: 15, height: 1.4, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                'assets/images/hall_principal.png',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),

            // ---- Sección Mapa de la Institución ----
            const Text(
              'Mapa de la Institución',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                'assets/images/mapa.png',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),

            // ---- Leyenda de íconos ----
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.exit_to_app, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Ícono de salida del Instituto',
                    style: TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.circle_outlined, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Ícono que delimita el sector donde deben esperar los usuarios',
                    style: TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // ---- Texto adicional (como dice el mockup) ----
            const Center(
              child: Text(
                'En el mapa se puede observar el punto de encuentro señalado con un círculo azul cerca de la salida principal del instituto.',
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),

      // ---- Barra inferior ----
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 3),
    );
  }
}
