# app_vamos_juntos

## Fecha de proximos avances sabado 8 de noviembre (Interfaces sin funcionalidades listas)

## Mockups
1. Inicio de Sesion 👍🏻
2. Crear Cuenta 👍🏻
3. Pagina de Inicio 👍🏻
4. Chats Globales
5. Chat grupal por hora
6. Salidas Grupales
7. Seleccion de Paradero y Micro
8. Salida Grupal (Lista de Personas)
9. Informacion de los paraderos
10. Informacion de los puntos de encuentro
11. Perfil

## Models

## Parte del Primo
* Modelo de datos para: 
    - usuarios (id, nombre, apellido, carrera, telefono_personal, email)

    - salidas (id, usuario_fk, chat_fk, punto_encuentro, hora_salida, /micros/)

    - salida_participantes (id, salida_fk, usuario_fk, /estado/)

    - chat_participantes (id, chat_fk, usuario_fk)

    - chats (id, destino o paradero, hora_inicio, hora_salida, salidas grupales)

    - mensajes (id, chat_fk, usuario_fk, contenido, hora_enviado)

* Mockups a realizar: 1, 2, 3 y 4

## Parte del Chetar
* Mokcups a realizar: 5, 6, 7, 8

## Parte del Cristian
* Mockups a realizar: 9, 10, 11

## Cosas que deben saber sobre Flutter

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

## Cosas a mejorar y a agregar
- Crear chats para cada salida.
- Agregar funcionalidad de foto de perfil en los datos.