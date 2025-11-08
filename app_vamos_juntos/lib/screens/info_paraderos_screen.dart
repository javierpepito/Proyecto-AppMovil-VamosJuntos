import 'package:flutter/material.dart';
import '../widgets/barra_navegacion.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: InfoParaderosPage(),
    );
  }
}

class InfoParaderosPage extends StatelessWidget {
  final List<Map<String, dynamic>> paraderos = [
    {
      'codigo': 'PB1559 - Parada 1',
      'descripcion':
          'Paradero cerca de gasolinera Aramco en el cruce entre Av. Pdte. Eduardo Frei Montalva y Catorce de la fama',
      'rutas': ['303', '307', '314'],
      'imagen': 'assets/images/paradero1.png',
    },
    {
      'codigo': 'PB422 - Parada 2',
      'descripcion':
          'Paradero cerca del parque en el cruce entre Av. Pdte. Eduardo Frei Montalva y Catorce de la fama',
      'rutas': ['303', '307', '314'],
      'imagen': 'assets/images/paradero2.png',
    },
    {
      'codigo': 'PB2025 - Parada 3',
      'descripcion':
          'Paradero entre el cruce de Av. Pdte. Eduardo Frei Montalva y Av. Dorsal',
      'rutas': ['101', '107', '107c', 'B17'],
      'imagen': 'assets/images/paradero3.png',
    },
    {
      'codigo': 'PB1563 - Parada 4',
      'descripcion':
          'Paradero a lado de la fabrica Dunlop entre el cruce de Av. Pdte. Eduardo Frei Montalva y la calle Roma ',
      'rutas': ['101', '107', '107c', 'B17'],
      'imagen': 'assets/images/paradero4.png',
    },
  ];

  InfoParaderosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Información de los Paraderos',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w400),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: paraderos.length,
        itemBuilder: (context, index) {
          final paradero = paraderos[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Text(
                  paradero['codigo'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                // Rutas
                Row(
                  children: [
                    for (var ruta in paradero['rutas'])
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.teal,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          ruta,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // Descripción
                Text(
                  paradero['descripcion'],
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 10),

                // Imagen
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.asset(
                    paradero['imagen'],
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          );
        },
      ),

      // Barra de navegación inferior
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
    );
  }
}
