import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
//import '../services/salida_service.dart';
import '../models/salida_model.dart';
import '../models/chat_model.dart';
import '../main.dart'; 
import 'selector_paraderos_screen.dart';
import 'salida_detalle_screen.dart';
import 'notificaciones_historial_screen.dart';
import 'notificaciones_diagnostico_screen.dart';
import '../widgets/barra_navegacion.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _notificationService = NotificationService();
  final PageController _tipsController = PageController();
  
  String _userName = 'Usuario';
  bool _isLoading = true;
  SalidaModel? _salidaActual;
  ChatModel? _chatDeLaSalida;
  String? _currentUserId;
  int _notificacionesNoLeidas = 0;
  int _tipsPage = 0;

  final List<String> _tips = const [
    'Antes de salir revisa tus rutas y comparte tu trayecto con un amigo.',
    'Mantén tu teléfono con suficiente batería y lleva un cargador portátil.',
    'Evita zonas poco iluminadas y usa rutas principales siempre que puedas.',
    'Si notas algo sospechoso, busca un lugar concurrido y avisa a un conocido.',
  ];

  @override
  void initState() {
    super.initState();
    _currentUserId = _authService.usuarioActual?.id;
    _cargarDatos();
  }

  @override
  void dispose() {
    _tipsController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    
    try {
      // Cargar datos del usuario
      final user = await _authService.obtenerPerfilUsuario();
      
      // Obtener salida actual del usuario
      final salidaActual = await _obtenerSalidaActual();
      
      // Obtener número de notificaciones no leídas
      final noLeidas = await _notificationService.obtenerNoLeidas();
      
      setState(() {
        _userName = user.nombreCompleto;
        _salidaActual = salidaActual;
        _notificacionesNoLeidas = noLeidas;
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout,
                  color: Colors.red,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),

              // Título
              const Text(
                'Cerrar sesión',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Mensaje
              const Text(
                '¿Estás seguro que deseas cerrar sesión?',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cerrar sesión',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmar == true && mounted) {
      await _authService.cerrarSesion();
      // El AuthWrapper en main.dart detectará el cierre de sesión
      // y navegará automáticamente a LoginScreen
    }
  }

  void _irAChats() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SelectorParaderosScreen()),
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

  void _irANotificaciones() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificacionesHistorialScreen(),
      ),
    ).then((_) => _cargarDatos()); // Recargar al volver para actualizar badge
  }

  void _irADiagnosticoNotificaciones() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificacionesDiagnosticoScreen(),
      ),
    );
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
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.black),
                onPressed: _irANotificaciones,
                onLongPress: _irADiagnosticoNotificaciones,
                tooltip: 'Mantén presionado para diagnóstico',
              ),
              if (_notificacionesNoLeidas > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _notificacionesNoLeidas > 9 ? '9+' : _notificacionesNoLeidas.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
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

                    // Accesos rápidos
                    const Text(
                      'Accesos rápidos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Tarjeta de acceso rápido a chats
                    InkWell(
                      onTap: _irAChats,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00BCD4), Color(0xFF0083B0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.teal.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.chat, color: Colors.white, size: 32),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Ir a Chats',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Ingresa rápido y elige tu paradero para ver los chats disponibles.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Consejos en carrusel
                    const Text(
                      'Consejos de seguridad',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 150,
                      child: PageView.builder(
                        controller: _tipsController,
                        itemCount: _tips.length,
                        onPageChanged: (i) => setState(() => _tipsPage = i),
                        itemBuilder: (context, index) {
                          final tip = _tips[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: const Color(0xFFFFB74D)),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFB74D).withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.lightbulb_outline, color: Color(0xFFFF9800), size: 28),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      tip,
                                      style: const TextStyle(
                                        color: Color(0xFF664D00),
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_tips.length, (i) {
                        final selected = i == _tipsPage;
                        return Container(
                          width: selected ? 16 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFFFF9800) : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        );
                      }),
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