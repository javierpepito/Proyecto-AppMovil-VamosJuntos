import 'package:flutter/material.dart';

class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ---- Contenido principal ----
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Imagen de perfil
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey,
                child: Icon(
                  Icons.person,
                  size: 70,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 15),

              // Nombre
              const Text(
                'Javier Andres Méndez Sepulveda',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 25),

              // Título sección
              const Text(
                'Datos Personales',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 10),

              // Caja de datos personales
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade400, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Carrera: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: 'Ingeniería en Informática'),
                        ],
                      ),
                    ),
                    const Divider(height: 20, thickness: 1),

                    // Teléfono con icono de edición
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Teléfono Personal: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: '+569 89681256'),
                              ],
                            ),
                          ),
                        ),
                        Icon(Icons.edit, color: Colors.black54, size: 20),
                      ],
                    ),

                    const Divider(height: 20, thickness: 1),

                    const Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Correo INACAP: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                              text: 'javier.mendez15@inacapmail.cl',
                              style: TextStyle(height: 1.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Botón cerrar sesión
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                ),
                onPressed: () {
                  // Aquí más adelante agregarás la función de cerrar sesión
                },
                child: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),

      // ---- Barra inferior ----
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade800,
        unselectedItemColor: Colors.grey,
        currentIndex: 4, // Esta es la pestaña de perfil
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
      ),
    );
  }
}
