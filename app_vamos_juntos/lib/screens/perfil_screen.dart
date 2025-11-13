import 'package:flutter/material.dart';
import '../widgets/barra_navegacion.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'login_screen.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final _authService = AuthService();
  UserModel? _usuario;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    try {
      final usuario = await _authService.obtenerPerfilUsuario();
      setState(() {
        _usuario = usuario;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar perfil: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editarCampo({
    required String titulo,
    required String valorActual,
    required bool esCarrera,
  }) async {
    final controller = TextEditingController(text: valorActual);
    
    final resultado = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar $titulo'),
        content: TextField(
          controller: controller,
          keyboardType: esCarrera ? TextInputType.text : TextInputType.phone,
          maxLength: esCarrera ? 100 : 12,
          decoration: InputDecoration(
            labelText: titulo,
            hintText: esCarrera ? 'Ej: Ingeniería en Informática' : 'Ej: +56912345678',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final valor = controller.text.trim();
              if (valor.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('El campo no puede estar vacío'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context, valor);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800,
            ),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (resultado != null && resultado != valorActual) {
      await _guardarCambios(
        carrera: esCarrera ? resultado : null,
        telefono: !esCarrera ? resultado : null,
      );
    }
  }

  Future<void> _guardarCambios({String? carrera, String? telefono}) async {
    setState(() => _isLoading = true);
    
    try {
      await _authService.actualizarPerfil(
        carrera: carrera,
        telefonoPersonal: telefono,
      );
      
      await _cargarDatosUsuario();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      try {
        await _authService.cerrarSesion();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cerrar sesión: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // Imagen de perfil
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue.shade800,
                      child: Text(
                        _usuario?.iniciales ?? '??',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Nombre
                    Text(
                      _usuario?.nombreCompleto ?? 'Usuario',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
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
                          // Carrera con icono de edición
                          InkWell(
                            onTap: () => _editarCampo(
                              titulo: 'Carrera',
                              valorActual: _usuario?.carrera ?? '',
                              esCarrera: true,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        const TextSpan(
                                          text: 'Carrera: ',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        TextSpan(
                                          text: _usuario?.carrera ?? 'No especificada',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Icon(Icons.edit, color: Colors.blue, size: 20),
                              ],
                            ),
                          ),
                          const Divider(height: 20, thickness: 1),

                          // Teléfono con icono de edición
                          InkWell(
                            onTap: () => _editarCampo(
                              titulo: 'Teléfono Personal',
                              valorActual: _usuario?.telefonoPersonal ?? '',
                              esCarrera: false,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        const TextSpan(
                                          text: 'Teléfono Personal: ',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        TextSpan(
                                          text: _usuario?.telefonoPersonal ?? 'No especificado',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Icon(Icons.edit, color: Colors.blue, size: 20),
                              ],
                            ),
                          ),

                          const Divider(height: 20, thickness: 1),

                          // Correo INACAP
                          Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'Correo INACAP: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text: _usuario?.email ?? 'No especificado',
                                  style: const TextStyle(height: 1.5),
                                ),
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
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                      ),
                      onPressed: _cerrarSesion,
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
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 4),
    );
  }
}