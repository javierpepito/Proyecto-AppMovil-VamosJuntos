import 'package:flutter/material.dart';
import '../services/auth_service.dart';
//import '../services/salida_service.dart';
import '../models/salida_model.dart';
import '../models/chat_model.dart';
import '../main.dart'; 
import 'login_screen.dart';
import 'lista_chats_screen.dart';
import 'salida_detalle_screen.dart';
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
  SalidaModel? _salidaActual;
  ChatModel? _chatDeLaSalida;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _authService.usuarioActual?.id;
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    
    try {
      // Cargar datos del usuario
      final user = await _authService.obtenerPerfilUsuario();
      
      // Obtener salida actual del usuario
      final salidaActual = await _obtenerSalidaActual();
      
      setState(() {
        _userName = user.nombreCompleto;
        _salidaActual = salidaActual;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _userName = 'Usuario';
        _isLoading = false;
      });
    }
  }

  /// Obtener la salida actual del usuario (si existe)
  Future<SalidaModel?> _obtenerSalidaActual() async {
    if (_currentUserId == null) return null;

    try {
      // Obtener todas las salidas donde el usuario está inscrito
      final response = await supabase
          .from('salida_participantes')
          .select('salida_id, salidas!inner(*)')
          .eq('usuario_id', _currentUserId!);

      final participaciones = response as List;
      
      if (participaciones.isEmpty) return null;

      // Buscar la primera salida disponible
      for (var participacion in participaciones) {
        final salidaData = participacion['salidas'];
        final salida = SalidaModel.fromJson(salidaData);

        // Si encontramos una salida disponible, devolverla
        if (salida.estaDisponible) {
          // Obtener el chat de esta salida
          await _obtenerChatDeLaSalida(salida.chatId);
          return salida;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Obtener el chat al que pertenece la salida
  Future<void> _obtenerChatDeLaSalida(String? chatId) async {
    if (chatId == null) return;

    try {
      final response = await supabase
          .from('chats')
          .select()
          .eq('id', chatId)
          .single();

      setState(() {
        _chatDeLaSalida = ChatModel.fromJson(response);
      });
    } catch (e) {
      // No hacer nada si falla
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

  void _irAChats() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatsListScreen()),
    ).then((_) => _cargarDatos()); // Recargar al volver
  }

  void _verDetalleSalida() {
    if (_salidaActual == null || _chatDeLaSalida == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SalidaDetalleScreen(
          salida: _salidaActual!,
          chat: _chatDeLaSalida!,
        ),
      ),
    ).then((_) => _cargarDatos()); // Recargar al volver
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
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: _cerrarSesion,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarDatos,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 150,
                        height: 150,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Bienvenida
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Bienvenido $_userName',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Coordina salidas seguras con tus compañeros',
                            style: TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Salida grupal actual
                    const Text(
                      'Salida grupal actual',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Card de salida actual o mensaje de no estar en ninguna
                    _salidaActual != null
                        ? _buildSalidaActualCard()
                        : _buildNoSalidaCard(),

                    const SizedBox(height: 30),

                    // Información importante
                    const Text(
                      'Información importante',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Card informativa
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BCD4),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Para poder unirte a una salida grupal debes entrar a un chat',
                            style: TextStyle(color: Colors.white, fontSize: 15),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 15),
                          ElevatedButton(
                            onPressed: _irAChats,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF4081),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Ir a Chats',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Consejo de seguridad
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4081),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Text(
                        'Consejo de seguridad: Antes de salir revisa tus rutas',
                        style: TextStyle(color: Colors.white, fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Versión
                    const Center(
                      child: Text(
                        'Versión - 1.0',
                        style: TextStyle(
                          color: Color(0xFF00BCD4),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }

  /// Widget cuando NO hay salida actual
  Widget _buildNoSalidaCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D47A1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Text(
        'En este momento no estás dentro de ninguna salida grupal',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Widget cuando SÍ hay salida actual
  Widget _buildSalidaActualCard() {
    return InkWell(
      onTap: _verDetalleSalida,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.shade600,
              Colors.green.shade800,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.green.shade300,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Estás en una salida grupal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 20),
              ],
            ),
            const SizedBox(height: 16),

            // Información de la salida
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hora de salida
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Hora: ${_salidaActual!.horaFormateada}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Punto de encuentro
                  Row(
                    children: [
                      const Icon(Icons.place, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _salidaActual!.puntoEncuentro,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Paradero (si hay chat)
                  if (_chatDeLaSalida != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.directions_bus, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _chatDeLaSalida!.paradero,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Tiempo restante
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _salidaActual!.tiempoRestante,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Botón para ver detalles
            const Text(
              'Toca para ver detalles',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}