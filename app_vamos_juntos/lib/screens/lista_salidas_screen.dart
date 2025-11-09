import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../models/salida_model.dart';
import '../services/salida_service.dart';
import '../services/auth_service.dart';
import 'salida_detalle_screen.dart';

class SalidasListScreen extends StatefulWidget {
  final ChatModel chat;

  const SalidasListScreen({super.key, required this.chat});

  @override
  State<SalidasListScreen> createState() => _SalidasListScreenState();
}

class _SalidasListScreenState extends State<SalidasListScreen> {
  final _salidaService = SalidaService();
  final _authService = AuthService();

  List<SalidaModel> _salidas = [];
  Map<String, int> _participantesPorSalida = {};
  Map<String, bool> _estoyUnido = {};
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _authService.usuarioActual?.id;
    _cargarSalidas();
  }

  Future<void> _cargarSalidas() async {
    setState(() => _isLoading = true);

    try {
      final salidas = await _salidaService.obtenerSalidasDeChat(widget.chat.id);

      // Obtener información de participación para cada salida
      for (var salida in salidas) {
        final numParticipantes = await _salidaService.obtenerNumeroParticipantes(salida.id);
        _participantesPorSalida[salida.id] = numParticipantes;

        if (_currentUserId != null) {
          final estoyUnido = await _salidaService.estaEnSalida(salida.id, _currentUserId!);
          _estoyUnido[salida.id] = estoyUnido;
        }
      }

      setState(() {
        _salidas = salidas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar salidas: $e')),
        );
      }
    }
  }

  Color _getColorForSalida(SalidaModel salida, int index) {
    if (!salida.estaDisponible) {
      return Colors.grey;
    } else if (salida.estaProxima) {
      return Colors.red;
    } else if (index == 0) {
      return Colors.teal;
    } else if (index == 1) {
      return Colors.blue;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Salidas Grupales',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _salidas.isEmpty
              ? const Center(
                  child: Text(
                    'No hay salidas disponibles para este chat',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : Column(
                  children: [
                    // Información del chat
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Colors.blue.shade50,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chat ${widget.chat.horarioFormateado}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.chat.paradero,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Elige la hora a la que deseas irte:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Lista de salidas
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _cargarSalidas,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _salidas.length,
                          itemBuilder: (context, index) {
                            final salida = _salidas[index];
                            final numParticipantes = _participantesPorSalida[salida.id] ?? 0;
                            final estoyUnido = _estoyUnido[salida.id] ?? false;
                            final color = _getColorForSalida(salida, index);
                            final disponible = salida.estaDisponible;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: InkWell(
                                onTap: disponible
                                    ? () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => SalidaDetalleScreen(
                                              salida: salida,
                                              chat: widget.chat,
                                            ),
                                          ),
                                        ).then((_) => _cargarSalidas());
                                      }
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(15),
                                    border: estoyUnido
                                        ? Border.all(color: Colors.white, width: 3)
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      // Icono
                                      Icon(
                                        estoyUnido ? Icons.check_circle : Icons.groups,
                                        color: Colors.white,
                                        size: 50,
                                      ),
                                      const SizedBox(width: 16),

                                      // Información
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Salida Grupal de',
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.9),
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              salida.horaFormateada,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            if (disponible)
                                              Text(
                                                salida.tiempoRestante,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            if (!disponible)
                                              const Text(
                                                'No disponible',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),

                                      // Contador de participantes
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              '$numParticipantes',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const Text(
                                              '/9',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}