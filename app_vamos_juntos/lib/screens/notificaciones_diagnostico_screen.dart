import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificacionesDiagnosticoScreen extends StatefulWidget {
  const NotificacionesDiagnosticoScreen({super.key});

  @override
  State<NotificacionesDiagnosticoScreen> createState() => _NotificacionesDiagnosticoScreenState();
}

class _NotificacionesDiagnosticoScreenState extends State<NotificacionesDiagnosticoScreen> {
  final _notificationService = NotificationService();
  String _logs = '';

  @override
  void initState() {
    super.initState();
    _verificarEstado();
  }

  Future<void> _verificarEstado() async {
    final ahora = tz.TZDateTime.now(tz.local);
    final ahoraLocal = DateTime.now();
    final habilitadas = await _notificationService.notificacionesHabilitadas();
    final alarmasExactas = await _notificationService.alarmasExactasHabilitadas();
    
    setState(() {
      _logs = '''
🕐 DIAGNÓSTICO DE NOTIFICACIONES

✅ Zona Horaria TZ: ${tz.local.name}
✅ DateTime.now(): $ahoraLocal
✅ TZDateTime.now(): $ahora
✅ Offset UTC: ${ahora.timeZoneOffset}

📱 PERMISOS:
${habilitadas ? '✅' : '❌'} Notificaciones: ${habilitadas ? 'HABILITADAS' : 'DESHABILITADAS'}
${alarmasExactas ? '✅' : '❌'} Alarmas Exactas: ${alarmasExactas ? 'HABILITADAS' : 'DESHABILITADAS'}

${!habilitadas ? '\n⚠️ Las notificaciones están DESHABILITADAS.\nVe a configuración del dispositivo.\n' : ''}
${!alarmasExactas ? '\n❌ ¡PROBLEMA ENCONTRADO!\nLas alarmas exactas están DESHABILITADAS.\nEsto impide que las notificaciones programadas funcionen.\n\n🔧 SOLUCIÓN:\n1. Presiona el botón "Abrir Configuración" abajo\n2. Busca "Alarmas y recordatorios"\n3. HABILÍTALO\n' : ''}
''';
    });
  }

  Future<void> _enviarNotificacionINMEDIATA() async {
    try {
      // Enviar notificación SIN programar (inmediata)
      await _notificationService.mostrarNotificacionInmediata(
        titulo: '✅ PRUEBA INMEDIATA',
        mensaje: 'Si ves esto, los permisos están OK y las notificaciones funcionan!',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Notificación enviada AHORA MISMO'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      setState(() {
        _logs += '\n\n📱 Notificación INMEDIATA enviada\n⏰ Debería aparecer YA';
      });
    } catch (e) {
      setState(() {
        _logs += '\n\n❌ Error: $e';
      });
    }
  }

  Future<void> _enviarNotificacionInmediata() async {
    try {
      final ahora = tz.TZDateTime.now(tz.local);
      final notifInmediata = ahora.add(const Duration(seconds: 3));
      
      await _notificationService.programarNotificacionesSalida(
        salidaId: 'test-${DateTime.now().millisecondsSinceEpoch}',
        horaSalida: notifInmediata.toLocal(),
        puntoEncuentro: 'Punto de Prueba - Diagnóstico',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Notificación de prueba programada para en 5 segundos'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      setState(() {
        _logs += '\n\n📱 Notificación de PRUEBA enviada\n⏰ Debería llegar en 5 segundos';
      });
    } catch (e) {
      setState(() {
        _logs += '\n\n❌ Error: $e';
      });
    }
  }

  Future<void> _enviarNotificacionEn2Minutos() async {
    try {
      final ahora = tz.TZDateTime.now(tz.local);
      final notifFutura = ahora.add(const Duration(minutes: 2));
      
      await _notificationService.programarNotificacionesSalida(
        salidaId: 'test-2min-${DateTime.now().millisecondsSinceEpoch}',
        horaSalida: notifFutura.toLocal(),
        puntoEncuentro: 'Punto de Prueba - 2 Minutos',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Salida programada para 2 minutos desde ahora'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      setState(() {
        _logs += '\n\n📱 Salida programada para dentro de 2 minutos\n⏰ Hora salida: $notifFutura\n⚠️ NO habrá notif de 10 min (falta poco tiempo)\n✅ SÍ habrá notif del momento exacto';
      });
    } catch (e) {
      setState(() {
        _logs += '\n\n❌ Error: $e';
      });
    }
  }

  Future<void> _enviarSalidaEn15Minutos() async {
    try {
      final ahora = tz.TZDateTime.now(tz.local);
      final notifFutura = ahora.add(const Duration(minutes: 15));
      
      await _notificationService.programarNotificacionesSalida(
        salidaId: 'test-15min-${DateTime.now().millisecondsSinceEpoch}',
        horaSalida: notifFutura.toLocal(),
        puntoEncuentro: 'Punto de Prueba - 15 Minutos',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Salida programada para 15 minutos desde ahora'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      setState(() {
        _logs += '\n\n📱 Salida programada para dentro de 15 minutos\n⏰ Hora salida: $notifFutura\n✅ Notif 10 min antes: ${ahora.add(const Duration(minutes: 5))}\n✅ Notif momento: $notifFutura';
      });
    } catch (e) {
      setState(() {
        _logs += '\n\n❌ Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnóstico de Notificaciones'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '🧪 Herramienta de Diagnóstico',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Logs
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _logs,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            // Botón: Abrir configuración
            ElevatedButton.icon(
              onPressed: () async {
                await _notificationService.abrirConfiguracionAlarmas();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ve a "Alarmas y recordatorios" y HABILÍTALO'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 5),
                    ),
                  );
                }
                
                // Esperar un poco y volver a verificar
                await Future.delayed(const Duration(seconds: 2));
                _verificarEstado();
              },
              icon: const Icon(Icons.settings),
              label: const Text('Abrir Configuración de Alarmas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Botón: Notificación INMEDIATA (sin programar)
            ElevatedButton.icon(
              onPressed: _enviarNotificacionINMEDIATA,
              icon: const Icon(Icons.notifications_active),
              label: const Text('Notificación INMEDIATA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Botón: Notificación programada
            ElevatedButton.icon(
              onPressed: _enviarNotificacionInmediata,
              icon: const Icon(Icons.flash_on),
              label: const Text('Notificación Programada (5 seg)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Botón: Salida en 2 minutos
            ElevatedButton.icon(
              onPressed: _enviarNotificacionEn2Minutos,
              icon: const Icon(Icons.timer),
              label: const Text('Salida en 2 Minutos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Botón: Salida en 15 minutos
            ElevatedButton.icon(
              onPressed: _enviarSalidaEn15Minutos,
              icon: const Icon(Icons.schedule),
              label: const Text('Salida en 15 Minutos (Completo)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Información
            Card(
              color: Colors.blue[50],
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 Problema Identificado:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '❌ Las notificaciones programadas NO funcionan porque las ALARMAS EXACTAS están deshabilitadas.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    Text('🔧 SOLUCIÓN PASO A PASO:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    SizedBox(height: 8),
                    Text('1. Presiona "Abrir Configuración de Alarmas" (botón NARANJA arriba)'),
                    Text('2. Busca la opción "Alarmas y recordatorios" o "Alarms & reminders"'),
                    Text('3. ACTÍVALO (cambia el switch a ON)'),
                    Text('4. Vuelve a la app'),
                    Text('5. Prueba nuevamente con "Notificación Programada (5 seg)"'),
                    SizedBox(height: 12),
                    Text(
                      '📱 NOTA: Este permiso es obligatorio desde Android 12+ para notificaciones programadas con hora exacta.',
                      style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
