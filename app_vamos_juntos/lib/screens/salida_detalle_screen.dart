import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../models/salida_model.dart';
import '../models/salida_participante_model.dart';
import '../services/salida_service.dart';
import '../services/auth_service.dart';

class SalidaDetalleScreen extends StatefulWidget {
  final SalidaModel salida;
  final ChatModel chat;

  const SalidaDetalleScreen({
    super.key,
    required this.salida,
    required this.chat,
  });

  @override
  State<SalidaDetalleScreen> createState() => _SalidaDetalleScreenState();
}

class _SalidaDetalleScreenState extends State<SalidaDetalleScreen> {
  final _salidaService = SalidaService();
  final _authService = AuthService();

  List<SalidaParticipanteModel> _participantes = [];
  bool _isLoading = true;
  bool _estoyUnido = false;
  String? _currentUserId;
  String? _miMicro;

  final List<String> _micros = ['307', '314', '303'];

  @override
  void initState() {
    super.initState();
    _currentUserId = _authService.usuarioActual?.id;
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    try {
      final participantes = await _salidaService.obtenerParticipantes(widget.salida.id);

      if (_currentUserId != null) {
        final estoyUnido = await _salidaService.estaEnSalida(widget.salida.id, _currentUserId!);
        final micro = await _salidaService.obtenerMicroUsuario(widget.salida.id, _currentUserId!);

        setState(() {
          _estoyUnido = estoyUnido;
          _miMicro = micro;
        });
      }

      setState(() {
        _participantes = participantes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _unirseASalida() async {
    if (_currentUserId == null) return;

    try {
      await _salidaService.unirseASalida(widget.salida.id, _currentUserId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Te has unido a la salida'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _cargarDatos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _salirDeSalida() async {
    if (_currentUserId == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salir de la salida'),
        content: const Text('¿Estás seguro que deseas salir de esta salida grupal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _salidaService.salirDeSalida(widget.salida.id, _currentUserId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Has salido de la salida'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      await _cargarDatos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _seleccionarMicro() async {
    if (_currentUserId == null) return;

    final microSeleccionado = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecciona tu micro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _micros.map((micro) {
            return ListTile(
              title: Text(
                micro,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              selected: _miMicro == micro,
              selectedColor: Colors.blue,
              onTap: () => Navigator.pop(context, micro),
            );
          }).toList(),
        ),
      ),
    );

    if (microSeleccionado == null) return;

    try {
      if (_estoyUnido) {
        await _salidaService.actualizarMicro(widget.salida.id, _currentUserId!, microSeleccionado);
      } else {
        await _salidaService.unirseASalida(widget.salida.id, _currentUserId!, micro: microSeleccionado);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Micro $microSeleccionado seleccionado')),
        );
      }

      await _cargarDatos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Salida de ${widget.salida.horaFormateada}',
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Información de la salida
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  color: Colors.blue.shade800,
                  child: Column(
                    children: [
                      const Icon(Icons.directions_bus, color: Colors.white, size: 60),
                      const SizedBox(height: 12),
                      Text(
                        'Salida Grupal de ${widget.salida.horaFormateada}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.salida.puntoEncuentro,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      if (widget.salida.estaDisponible)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.salida.tiempoRestante,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Participantes
                Expanded(
                  child: _participantes.isEmpty
                      ? const Center(
                          child: Text(
                            'Aún no hay participantes.\n¡Sé el primero en unirte!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _participantes.length,
                          itemBuilder: (context, index) {
                            final participante = _participantes[index];
                            final esMiPerfil = participante.usuarioId == _currentUserId;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: esMiPerfil ? Colors.blue.shade50 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: esMiPerfil
                                    ? Border.all(color: Colors.blue.shade800, width: 2)
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.blue.shade800,
                                    child: Text(
                                      participante.usuario?.iniciales ?? '??',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          participante.usuario?.nombreCompleto ?? 'Usuario',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (participante.micro != null)
                                          Text(
                                            'Micro: ${participante.micro}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (esMiPerfil)
                                    const Chip(
                                      label: Text('Tú', style: TextStyle(color: Colors.white)),
                                      backgroundColor: Colors.blue,
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                // Botones de acción
                if (widget.salida.estaDisponible)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (_estoyUnido) ...[
                          // Botón para seleccionar micro
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _seleccionarMicro,
                              icon: const Icon(Icons.directions_bus),
                              label: Text(_miMicro != null
                                  ? 'Cambiar Micro (Actual: $_miMicro)'
                                  : 'Seleccionar Micro'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Botón para salir
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: _salirDeSalida,
                              icon: const Icon(Icons.exit_to_app),
                              label: const Text('Salir de esta salida'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red, width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          // Botón para unirse
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _unirseASalida,
                              icon: const Icon(Icons.person_add),
                              label: const Text('Unirme a esta salida'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}