import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../models/notificacion_historial_model.dart';
import 'package:intl/intl.dart';

class NotificacionesHistorialScreen extends StatefulWidget {
  const NotificacionesHistorialScreen({super.key});

  @override
  State<NotificacionesHistorialScreen> createState() => _NotificacionesHistorialScreenState();
}

class _NotificacionesHistorialScreenState extends State<NotificacionesHistorialScreen> {
  final _notificationService = NotificationService();
  List<NotificacionHistorialModel> _notificaciones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    setState(() => _isLoading = true);
    
    try {
      final historial = await _notificationService.obtenerHistorial();
      setState(() {
        _notificaciones = historial;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _marcarTodasComoLeidas() async {
    await _notificationService.marcarTodasComoLeidas();
    await _cargarHistorial();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todas las notificaciones marcadas como leídas'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _limpiarHistorial() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar historial'),
        content: const Text('¿Estás seguro que deseas eliminar todas las notificaciones?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _notificationService.limpiarHistorial();
      await _cargarHistorial();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Historial eliminado'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00BCD4),
        elevation: 0,
        title: const Text(
          'Notificaciones',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_notificaciones.isNotEmpty) ...[
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'marcar_todas') {
                  _marcarTodasComoLeidas();
                } else if (value == 'limpiar') {
                  _limpiarHistorial();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'marcar_todas',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, size: 20),
                      SizedBox(width: 12),
                      Text('Marcar todas como leídas'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'limpiar',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Limpiar historial', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notificaciones.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _cargarHistorial,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notificaciones.length,
                    itemBuilder: (context, index) {
                      final notificacion = _notificaciones[index];
                      return _buildNotificacionItem(notificacion);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          Text(
            'No hay notificaciones',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las notificaciones programadas\naparecerán aquí',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificacionItem(NotificacionHistorialModel notificacion) {
    final formatoFecha = DateFormat('dd/MM/yyyy');
    final formatoHora = DateFormat('HH:mm');
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: notificacion.leida ? Colors.white : const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notificacion.leida ? Colors.grey[200]! : const Color(0xFF00BCD4).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () async {
          if (!notificacion.leida) {
            await _notificationService.marcarComoLeida(notificacion.id);
            await _cargarHistorial();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono según el tipo
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getColorByType(notificacion.tipo),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    notificacion.icono,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Contenido
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notificacion.titulo,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notificacion.leida 
                                  ? FontWeight.normal 
                                  : FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (!notificacion.leida)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00BCD4),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    
                    Text(
                      notificacion.mensaje,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${formatoFecha.format(notificacion.fecha)} • ${formatoHora.format(notificacion.fecha)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• ${notificacion.tiempoTranscurrido}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Punto de encuentro si existe
                    if (notificacion.puntoEncuentro != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.place,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              notificacion.puntoEncuentro!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorByType(String tipo) {
    switch (tipo) {
      case '10min':
        return const Color(0xFFFFF3E0);
      case 'momento':
        return const Color(0xFFE8F5E9);
      default:
        return const Color(0xFFE3F2FD);
    }
  }
}
