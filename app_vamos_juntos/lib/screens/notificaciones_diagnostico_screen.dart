import 'package:flutter/material.dart';
import '../services/background_notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Pantalla simplificada solo para probar WorkManager
class NotificacionesDiagnosticoScreen extends StatefulWidget {
  const NotificacionesDiagnosticoScreen({super.key});

  @override
  State<NotificacionesDiagnosticoScreen> createState() => _NotificacionesDiagnosticoScreenState();
}

class _NotificacionesDiagnosticoScreenState extends State<NotificacionesDiagnosticoScreen> {
  String _logs = '';

  @override
  void initState() {
    super.initState();
    _logs = '✅ WorkManager está activo (revisa cada 15 minutos)\n\n';
    _logs += '📱 Para probar:\n';
    _logs += '1. Modifica una salida existente a 10 min después\n';
    _logs += '2. Ejecuta WorkManager manualmente\n';
    _logs += '3. Espera la notificación';
  }

  Future<void> _modificarSalida() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        _mostrarError('No estás logueado');
        return;
      }

      // Buscar salida donde el usuario es participante
      final response = await supabase
          .from('salida_participantes')
          .select('salida_id, salidas(id, hora_salida, punto_encuentro, estado)')
          .eq('usuario_id', userId)
          .limit(1);

      if (response.isEmpty) {
        _mostrarError('No tienes salidas como participante. Únete a una primero.');
        return;
      }

      final salidaData = response.first['salidas'];
      final salidaId = salidaData['id'];
      final punto = salidaData['punto_encuentro'];
      
      // Modificar a 10 minutos después
      final nuevaHora = DateTime.now().add(const Duration(minutes: 10));

      await supabase.from('salidas').update({
        'hora_salida': nuevaHora.toIso8601String(),
      }).eq('id', salidaId);

      setState(() {
        _logs += '\n\n✅ SALIDA MODIFICADA:';
        _logs += '\n   Punto: $punto';
        _logs += '\n   Nueva hora: ${nuevaHora.hour}:${nuevaHora.minute.toString().padLeft(2, "0")}';
        _logs += '\n   ID: $salidaId';
        _logs += '\n   Eres participante ✓';
        _logs += '\n\n💡 Ahora ejecuta WorkManager';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Salida a las ${nuevaHora.hour}:${nuevaHora.minute.toString().padLeft(2, "0")}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _mostrarError('Error: $e');
    }
  }

  Future<void> _ejecutarWorkManager() async {
    try {
      setState(() {
        _logs += '\n\n🔄 Ejecutando WorkManager...';
      });

      await BackgroundNotificationService.ejecutarAhora();

      setState(() {
        _logs += '\n✅ WorkManager ejecutado';
        _logs += '\n⏳ Espera 2-3 segundos...';
        _logs += '\n📱 Revisa si llegó la notificación';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WorkManager ejecutándose... Espera 3 seg'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      _mostrarError('Error: $e');
    }
  }

  void _mostrarError(String mensaje) {
    setState(() {
      _logs += '\n\n❌ $mensaje';
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔄 Test WorkManager'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'PRUEBA DE NOTIFICACIONES CON APP CERRADA',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'WorkManager revisa cada 15 minutos automáticamente',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            
            const SizedBox(height: 24),
            
            // Botón 1: Modificar salida
            ElevatedButton.icon(
              onPressed: _modificarSalida,
              icon: const Icon(Icons.edit_calendar),
              label: const Text('1️⃣ Modificar Salida (10 min)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Botón 2: Ejecutar WorkManager
            ElevatedButton.icon(
              onPressed: _ejecutarWorkManager,
              icon: const Icon(Icons.play_arrow),
              label: const Text('2️⃣ EJECUTAR WorkManager'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            
            const Text(
              'LOGS:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.teal, width: 2),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _logs,
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 12,
                      color: Colors.greenAccent,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
