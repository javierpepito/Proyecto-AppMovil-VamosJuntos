# Sistema de Notificaciones - VAMOS JUNTOS

## 📱 Implementación Completada

Se ha implementado un sistema completo de notificaciones para avisar a los usuarios sobre sus salidas programadas.

## ✨ Características

### Notificaciones Automáticas
- **10 minutos antes**: Aviso previo con la hora y punto de encuentro
- **Al momento de la salida**: Notificación cuando es hora de partir

### Gestión Inteligente
- Las notificaciones se programan automáticamente al unirse a una salida
- Se cancelan automáticamente al salir de una salida
- Zona horaria configurada para Chile (America/Santiago)

## 🔧 Archivos Modificados/Creados

### 1. **Dependencias** (`pubspec.yaml`)
```yaml
flutter_local_notifications: ^18.0.1
timezone: ^0.9.4
permission_handler: ^11.3.1
```

### 2. **Servicio de Notificaciones** (`lib/services/notification_service.dart`)
- Inicialización del sistema de notificaciones
- Configuración de zona horaria de Chile
- Programación de notificaciones con horarios exactos
- Solicitud de permisos para Android e iOS
- Cancelación de notificaciones

### 3. **Integración con Salidas** (`lib/services/salida_service.dart`)
- Al unirse a una salida: programa notificaciones automáticamente
- Al salir de una salida: cancela las notificaciones programadas

### 4. **Permisos Android** (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
```

### 5. **Inicialización** (`lib/main.dart`)
- Inicialización del servicio de notificaciones al iniciar la app

## 📋 Pasos para Completar la Configuración

### 1. Instalar Dependencias
```bash
cd app_vamos_juntos
flutter pub get
```

### 2. Para iOS (si vas a compilar para iOS)
Edita el archivo `ios/Runner/Info.plist` y agrega:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

### 3. Compilar y Probar
```bash
flutter run
```

## 🚀 Cómo Funciona

### Flujo de Usuario
1. **Usuario se une a una salida** programada para las 14:00
   - ✅ Se programa notificación para las 13:50 (10 min antes)
   - ✅ Se programa notificación para las 14:00 (hora exacta)

2. **10 minutos antes (13:50)**
   - 📱 Notificación: "🚌 ¡Tu salida es en 10 minutos!"
   - 📍 Punto de encuentro y hora incluidos

3. **Al momento de la salida (14:00)**
   - 📱 Notificación: "🚌 ¡Es hora de partir!"
   - 📍 Recordatorio del punto de encuentro

4. **Si el usuario sale de la salida antes**
   - 🔕 Todas las notificaciones se cancelan automáticamente

### Código Ejemplo
```dart
// Al unirse a una salida (automático)
await SalidaService().unirseASalida(
  salidaId,
  usuarioId,
  micro: 'A',
);
// ✅ Notificaciones programadas automáticamente

// Al salir de una salida (automático)
await SalidaService().salirDeSalida(salidaId, usuarioId);
// 🔕 Notificaciones canceladas automáticamente
```

## 🔔 Gestión de Permisos

### Android
- En Android 13+ (API 33), el sistema solicitará permiso de notificaciones automáticamente
- Para alarmas exactas (Android 12+), se solicita permiso adicional
- Los permisos se solicitan al inicializar la app

### iOS
- Se solicitan permisos de alerta, badge y sonido al iniciar
- El usuario debe aceptar en el diálogo del sistema

## 🧪 Pruebas Recomendadas

1. **Unirse a una salida próxima** (menos de 10 minutos)
   - Verificar que se recibe la notificación al momento correcto

2. **Unirse y luego salir de una salida**
   - Confirmar que las notificaciones se cancelan

3. **Verificar permisos**
```dart
final habilitadas = await NotificationService().notificacionesHabilitadas();
print('Notificaciones habilitadas: $habilitadas');
```

4. **Probar en diferentes horarios**
   - Salidas inmediatas (menos de 10 min)
   - Salidas futuras (más de 10 min)

## 📱 Plataformas Soportadas

- ✅ Android (API 21+)
- ✅ iOS (10.0+)
- ⚠️ Web (requiere configuración adicional)

## 🐛 Solución de Problemas

### Las notificaciones no aparecen
1. Verificar permisos en configuración del dispositivo
2. Revisar que la hora de la salida sea futura
3. Comprobar logs de debug para errores

### Android: Error de alarma exacta
- Verificar que el permiso `SCHEDULE_EXACT_ALARM` esté en el manifest
- En Android 12+, el usuario debe habilitar manualmente en configuración

### iOS: Notificaciones no autorizadas
- Reinstalar la app y aceptar los permisos cuando se soliciten
- Verificar configuración de notificaciones en ajustes del dispositivo

## 📝 Notas Importantes

- Las notificaciones solo se programan si la hora de salida es futura
- Si faltan menos de 10 minutos, solo se programa la notificación del momento exacto
- Las notificaciones persisten incluso si la app está cerrada
- El sistema usa alarmas exactas para garantizar puntualidad
- Zona horaria configurada: America/Santiago (Chile)

## 🔮 Mejoras Futuras Posibles

- [ ] Notificaciones personalizables (tiempo de anticipación)
- [ ] Sonidos personalizados para diferentes tipos de salida
- [ ] Notificaciones de recordatorio si hay cambios en la salida
- [ ] Integración con calendario del dispositivo
- [ ] Notificaciones push para cambios de última hora
- [ ] Estadísticas de notificaciones recibidas

---

**Estado**: ✅ Implementación completa y lista para usar
**Última actualización**: 8 de diciembre de 2025
