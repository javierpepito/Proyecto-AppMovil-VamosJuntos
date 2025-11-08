# app_vamos_juntos

## Fecha de proximos avances sabado 8 de noviembre (Interfaces sin funcionalidades listas)

## Mockups
1. Inicio de Sesion 👍🏻
2. Crear Cuenta 👍🏻
3. Pagina de Inicio 👍🏻
4. Chats Globales [primo]
5. Chat grupal por hora [primo]
6. Salidas Grupales
7. Seleccion de Paradero y Micro
8. Salida Grupal (Lista de Personas)
9. Informacion de los paraderos
10. Informacion de los puntos de encuentro
11. Perfil

## Models
- usuarios (id, nombre, apellido, carrera, telefono_personal, email)

- salidas (id, chat_fk, punto_encuentro, hora_salida, estado)

- salida_participantes (id, salida_fk, usuario_fk, micro)

- chat_participantes (id, chat_fk, usuario_fk)

- chats (id, destino o paradero, hora_inicio, hora_termino, fecha, estado)

- mensajes (id, chat_fk, usuario_fk, contenido, hora_enviado)

## Parte del Primo
* Mockups a realizar: 4

## Parte del Chetar
* Mokcups a realizar: 5, 6, 7, 8

## Parte del Cristian
* Mockups a realizar: 9, 10, 11

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

## Promp pendiente
- antes de seguir me gustaria saber si hay lugares en los que tendria que cambiar la zona horaria para que no me de problema mas tarde la fecha y la hora
- 12 chats por paradero y son 4 paraderos, ademas de tener 3 salidas por chat.

## Cosas a mejorar y a agregar
- Crear chats para cada salida.
- Agregar funcionalidad de foto de perfil en los datos.