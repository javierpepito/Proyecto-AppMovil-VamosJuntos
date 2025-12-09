import 'package:flutter/material.dart';
import '../widgets/barra_navegacion.dart';
import 'home_screen.dart';
import 'lista_chats_screen.dart';

class SelectorParaderosScreen extends StatefulWidget {
  const SelectorParaderosScreen({super.key});

  @override
  State<SelectorParaderosScreen> createState() =>
      _SelectorParaderosScreenState();
}

class _SelectorParaderosScreenState extends State<SelectorParaderosScreen> {
  // Lista de paraderos disponibles
  final List<Map<String, dynamic>> _paraderos = [
    {
      'codigo': 'PB1559',
      'nombre': 'Parada 1',
      'color': Colors.blue,
      'icon': Icons.directions_bus,
    },
    {
      'codigo': 'PB422',
      'nombre': 'Parada 2',
      'color': Colors.red,
      'icon': Icons.directions_bus,
    },
    {
      'codigo': 'PB2025',
      'nombre': 'Parada 3',
      'color': Colors.teal,
      'icon': Icons.directions_bus,
    },
    {
      'codigo': 'PB1563',
      'nombre': 'Parada 4',
      'color': Colors.pink,
      'icon': Icons.directions_bus,
    },
  ];

  void _irAChatsDelParadero(String paraderoCompleto) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChatsListScreen(paraderoFiltro: paraderoCompleto),
      ),
    ).then((_) {
      // Recargar si es necesario
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Selecciona tu Paradero',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // Si no hay a dónde volver (caso pushReplacement), ir a Home
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona el paradero de preferencia:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: _paraderos.length,
                itemBuilder: (context, index) {
                  final paradero = _paraderos[index];
                  final paraderoCompleto =
                      '${paradero['codigo']} - ${paradero['nombre']}';

                  return GestureDetector(
                    onTap: () => _irAChatsDelParadero(paraderoCompleto),
                    child: Container(
                      decoration: BoxDecoration(
                        color: paradero['color'] as Color,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (paradero['color'] as Color)
                                .withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () =>
                              _irAChatsDelParadero(paraderoCompleto),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                paradero['icon'] as IconData,
                                color: Colors.white,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                paradero['nombre'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                paradero['codigo'] as String,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Mensaje informativo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFB74D)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Color(0xFFFF9800), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Solo verás chats disponibles para el paradero seleccionado',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF664D00),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }
}
