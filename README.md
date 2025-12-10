# Aplicación Movil VamosJuntos

## Mockups
1. Inicio de Sesion ✓
2. Crear Cuenta ✓
3. Pagina de Inicio ✓
4. Chats Globales 
5. Chat grupal por hora ✓
6. Salidas Grupales ✓
7. Seleccion de Paradero ✓
8. Salida Grupal (Lista de Personas) ✓
9. Informacion de los paraderos ✓
10. Informacion de los puntos de encuentro 
11. Perfil ✓

## Requerimientos Funcionales Faltantes:
1. El sistema deberá tener chats públicos. ✓
2. El sistema deberá filtrar los chats por paradero de destino y hora. ✓
3. El sistema permitirá crear una cuenta en la app y se validará que sea estudiante. 
4. El sistema permitirá iniciar sesión con cuenta de la app. ✓
5. El sistema permitirá cerrar sesión de la cuenta. ✓
6. El sistema permitirá configurar datos de contacto y carrera. 
7. El sistema creara las salidas grupales en bloques de 20 min por cada hora o sea por cada chat. ✓
8. Los usuarios podrán unirse o salirse de una salida grupal. 
9. La salida grupal debe mostrar detalles de las personas que están unidas. ✓
10. El usuario podrá ver a la salida a la que está unido (Solo se puede estar unido a una). ✓
11. El sistema mostrara y detallara los destinos o paraderos que se usaran en la App. ✓
12. Deberá existir el rol de trabajador y estudiante. 
13. El sistema diferenciara chats para trabajadores y estudiantes. 
14. El sistema permitirá ver las ultimas notificaciones. 
15. El sistema notificará al usuario cuando su reunión esté a punto de realizarse (Antes de la salida para que llegue al punto). 
16. El usuario podrá ver todas las salidas grupales del chat en el que esta. ✓ 
17. Las salidas deben bloquearse una vez ya pasé su hora. ✓
18. El sistema deberá limpiar los chats y salidas al finalizar el día, dejándolo disponible para el próximo día. ✓
19. El sistema identificara malas palabras y registrara quien envió el mensaje, además deberá borrar el mensaje inmediatamente.  
20. El usuario podrá bloquear a otro usuario impidiéndole ver los mensajes que el envié. 
21. El sistema le preguntara que micro tomara al unirse a una salida dependiendo del paradero o destino de la salida. ✓
22. El sistema debe informar de puntos de encuentro para las salidas.  ✓

## Models
- usuarios (id, nombre, apellido, carrera, telefono_personal, email)
- salidas (id, chat_fk, punto_encuentro, hora_salida, estado)
- salida_participantes (id, salida_fk, usuario_fk, micro)
- chat_participantes (id, chat_fk, usuario_fk)
- chats (id, destino o paradero, hora_inicio, hora_termino, fecha, estado)
- mensajes (id, chat_fk, usuario_fk, contenido, hora_enviado)

## Seguridad de Supabase
Aqui va la seguridad de Supabase que fue deshabilitada, pero es altamente recomendable implementar.
+ Se deshabilito RLS y politicas en las tablas.
+ Se deshabilito la comfirmacion de correo electronico.

## Comandos
```bash
cd app_vamos_juntos
```

```bash
flutter run
```

```bash
flutter doctor
```

```bash
flutter devices
```

```bash
flutter run --release
```

```bash
flutter pub get
```

## Cosas pendientes de la APP
- confirmacion de correo electronico ya sea por supabase o por codigo.
- pantalla de carga al principio.
- Usar seguridad de supabase. 
- A tomar en cuenta: (Mencionar practicas OWASP, Demostrar la correccion del codigo)

## Iconos de la Aplicación
El icono de la aplicación se genera automáticamente desde `assets/images/logo.png` usando `flutter_launcher_icons`.

Para regenerar los iconos después de cambiar el logo:
```bash
dart run flutter_launcher_icons
```

La configuración está en `flutter_launcher_icons.yaml`.

## Notas importantes
- Los dominios permitidos son: `@inacapmail.cl` y `@inacap.cl`
- Los profesores deben estar registrados en la tabla `profesores` ANTES de crear su cuenta
- Si un profesor se registra antes de estar en la tabla, recibirá rol de estudiante
- Para cambiar el rol manualmente: `UPDATE usuarios SET rol = 'profesor' WHERE email = 'correo@inacap.cl'`