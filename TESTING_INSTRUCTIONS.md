# Filtro de Malas Palabras y Bloqueo de Usuarios

Este PR agrega funcionalidad de moderación de contenido y bloqueo de usuarios a la aplicación VamosJuntos.

## 📋 Resumen de Cambios

### Nuevos Archivos Flutter

1. **`app_vamos_juntos/lib/utils/validators.dart`**
   - Validadores reutilizables para formularios
   - Validación de email INACAP (@inacap.cl y @inacapmail.cl)
   - Validación de nombre/apellido (solo letras, 2-40 caracteres)
   - Validación de teléfono (8-12 dígitos)
   - Validador genérico de campos requeridos

2. **`app_vamos_juntos/lib/services/profanity_filter.dart`**
   - Filtro de malas palabras con carga lazy desde assets
   - Método `load()` para cargar la lista de palabras prohibidas
   - Método `containsProfanity(String)` para detectar palabras inapropiadas
   - Método `censor(String)` para censurar palabras con asteriscos
   - Implementado como singleton para eficiencia

3. **`app_vamos_juntos/lib/services/block_service.dart`**
   - Servicio para bloquear/desbloquear usuarios
   - Usa el email del JWT para mapear al ID del usuario en la tabla `usuarios`
   - Método `blockUser(blockedUsuarioId)` para bloquear un usuario
   - Método `unblockUser(blockedUsuarioId)` para desbloquear

4. **`app_vamos_juntos/assets/data/profanity_es.txt`**
   - Lista básica de palabras prohibidas en español
   - Formato: una palabra por línea
   - Soporta comentarios con `#`
   - **IMPORTANTE**: Ampliar esta lista según necesidades del contexto local

### Archivos Modificados

1. **`app_vamos_juntos/lib/services/chat_service.dart`**
   - Importa `ProfanityFilter`
   - Valida mensajes antes de enviarlos a la base de datos
   - Lanza excepción si el mensaje contiene palabras prohibidas
   - La UI puede capturar esta excepción y mostrar feedback al usuario

2. **`app_vamos_juntos/pubspec.yaml`**
   - Agregado `assets/data/profanity_es.txt` a la lista de assets

### Script SQL para Supabase

**`supabase/sql/profanity_and_blocking.sql`**

Este script debe ejecutarse **manualmente** desde el SQL Editor de Supabase (Dashboard > SQL Editor). Incluye:

#### Nuevas Tablas:
- `usuarios_bloqueados`: Registra bloqueos entre usuarios
- `profanity_words`: Almacena palabras prohibidas para el trigger del servidor
- `mensajes_moderacion`: Log de mensajes eliminados por moderación

#### Funciones y Triggers:
- `contains_profanity(text)`: Detecta malas palabras en texto
- `trg_mensajes_profanity()`: Trigger que elimina y loguea mensajes con malas palabras
- `current_usuario_id()`: Helper para obtener ID del usuario autenticado por email

#### Row Level Security (RLS):
- **usuarios**: Los usuarios solo pueden ver/editar su propio perfil
- **chat_participantes**: Los usuarios solo ven chats en los que participan
- **mensajes**: 
  - SELECT: Solo mensajes de chats donde el usuario participa, excluyendo mensajes de usuarios bloqueados
  - INSERT: Solo si el usuario es participante del chat
- **usuarios_bloqueados**: Los usuarios solo pueden ver/modificar sus propios bloqueos

## 🧪 Instrucciones de Prueba

### Requisitos Previos

1. Tener Flutter instalado y configurado
2. Acceso a Supabase (proyecto configurado)
3. Usuarios de prueba en Supabase Auth con emails @inacap.cl

### Paso 1: Instalar Dependencias

```bash
cd app_vamos_juntos
flutter pub get
```

### Paso 2: Ejecutar el Script SQL

1. Ir a Supabase Dashboard → SQL Editor
2. Copiar todo el contenido de `supabase/sql/profanity_and_blocking.sql`
3. Pegarlo en una nueva query
4. Ejecutar el script
5. Verificar que las tablas se crearon correctamente

**Opcional**: Agregar palabras a la tabla `profanity_words` para pruebas del trigger:

```sql
INSERT INTO public.profanity_words (word) VALUES 
  ('idiota'),
  ('tonto')
ON CONFLICT DO NOTHING;
```

### Paso 3: Cargar el Filtro de Profanidad al Iniciar la App

En `app_vamos_juntos/lib/main.dart`, después de inicializar Supabase, agregar:

```dart
// Cargar filtro de malas palabras
await ProfanityFilter.instance.load();
```

Ejemplo de integración en `main()`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  // Cargar filtro de malas palabras
  await ProfanityFilter.instance.load();
  
  runApp(const MyApp());
}
```

### Paso 4: Pruebas de Filtro de Malas Palabras

#### Prueba en Cliente (Flutter):

1. Iniciar sesión con un usuario
2. Ir a un chat activo
3. Intentar enviar un mensaje que contenga "idiota" o "tonto"
4. **Resultado esperado**: La app debe mostrar un error "El mensaje contiene palabras inapropiadas"
5. El mensaje NO debe aparecer en el chat

#### Prueba en Servidor (Trigger SQL):

Si un mensaje con malas palabras logra llegar a la base de datos (evadiendo la validación del cliente):

1. El trigger `tr_mensajes_profanity` lo detectará
2. Insertará un registro en `mensajes_moderacion` con el contenido
3. Eliminará el mensaje de la tabla `mensajes`
4. El mensaje NO aparecerá en el chat

**Verificar logs de moderación**:

```sql
SELECT * FROM public.mensajes_moderacion ORDER BY created_at DESC;
```

### Paso 5: Pruebas de Bloqueo de Usuarios

#### Obtener ID de usuario a bloquear:

```sql
SELECT id, email, nombre FROM public.usuarios LIMIT 5;
```

#### En la app (código de ejemplo):

```dart
import 'package:app_vamos_juntos/services/block_service.dart';

final blockService = BlockService();

// Bloquear usuario
try {
  await blockService.blockUser(blockedUsuarioId: 123); // Reemplazar con ID real
  print('Usuario bloqueado exitosamente');
} catch (e) {
  print('Error al bloquear: $e');
}

// Desbloquear usuario
try {
  await blockService.unblockUser(blockedUsuarioId: 123);
  print('Usuario desbloqueado exitosamente');
} catch (e) {
  print('Error al desbloquear: $e');
}
```

#### Verificar que mensajes de usuarios bloqueados no aparecen:

1. Usuario A bloquea a Usuario B
2. Usuario A refresca el chat
3. Los mensajes de Usuario B NO deben aparecer para Usuario A
4. Usuario B puede seguir viendo sus propios mensajes normalmente

**Verificar en base de datos**:

```sql
-- Ver bloqueos del usuario actual (reemplazar email)
SELECT b.*, u.nombre, u.email 
FROM public.usuarios_bloqueados b
JOIN public.usuarios u ON u.id = b.bloqueado_fk
WHERE b.usuario_fk = (SELECT id FROM usuarios WHERE email = 'tu@inacap.cl');
```

### Paso 6: Pruebas de Validadores

Los validadores en `validators.dart` están listos para usarse en formularios:

```dart
import 'package:app_vamos_juntos/utils/validators.dart';

TextFormField(
  decoration: InputDecoration(labelText: 'Email INACAP'),
  validator: Validators.emailInacap,
),

TextFormField(
  decoration: InputDecoration(labelText: 'Nombre'),
  validator: Validators.nombre,
),

TextFormField(
  decoration: InputDecoration(labelText: 'Teléfono'),
  validator: Validators.telefono,
),
```

## 🔒 Seguridad

### Doble Capa de Protección

1. **Capa Cliente (Flutter)**: Valida antes de enviar, mejora UX con feedback inmediato
2. **Capa Servidor (Trigger SQL)**: Protege contra manipulación del cliente o uso de API directa

### Políticas RLS

- Todos los datos están protegidos con Row Level Security
- Los usuarios solo pueden acceder a sus propios datos y chats donde participan
- Los mensajes de usuarios bloqueados son filtrados automáticamente por RLS

## 🚫 Limitaciones Conocidas

1. **Lista de palabras básica**: `profanity_es.txt` contiene solo ejemplos. Debe ampliarse según contexto local.
2. **Detección simple**: El filtro busca coincidencias exactas (no variantes con números/símbolos como "1d10t4").
3. **Sin notificaciones**: El usuario bloqueado no recibe notificación del bloqueo.
4. **Carga única**: El filtro carga palabras al inicio. Cambios en el archivo requieren reiniciar la app.

## 🔄 Rollback

Si necesitas revertir los cambios de base de datos:

```sql
-- Deshabilitar RLS
ALTER TABLE public.mensajes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_participantes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.usuarios DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.usuarios_bloqueados DISABLE ROW LEVEL SECURITY;

-- Eliminar policies
DROP POLICY IF EXISTS p_usuarios_self_select ON public.usuarios;
DROP POLICY IF EXISTS p_usuarios_self_update ON public.usuarios;
DROP POLICY IF EXISTS p_chat_participantes_select ON public.chat_participantes;
DROP POLICY IF EXISTS p_mensajes_select ON public.mensajes;
DROP POLICY IF EXISTS p_mensajes_insert ON public.mensajes;
DROP POLICY IF EXISTS p_bloq_select ON public.usuarios_bloqueados;
DROP POLICY IF EXISTS p_bloq_insert ON public.usuarios_bloqueados;
DROP POLICY IF EXISTS p_bloq_delete ON public.usuarios_bloqueados;

-- Eliminar trigger y función
DROP TRIGGER IF EXISTS tr_mensajes_profanity ON public.mensajes;
DROP FUNCTION IF EXISTS public.trg_mensajes_profanity();
DROP FUNCTION IF EXISTS public.contains_profanity(text);
DROP FUNCTION IF EXISTS public.current_usuario_id();

-- Eliminar tablas (CUIDADO: esto borra datos)
DROP TABLE IF EXISTS public.mensajes_moderacion;
DROP TABLE IF EXISTS public.profanity_words;
DROP TABLE IF EXISTS public.usuarios_bloqueados;
```

## 📝 Notas Importantes

- Este PR es un **DRAFT** y no afecta la rama `main` hasta que sea aprobado
- Los cambios en Flutter son **compatibles hacia atrás**: Si no se ejecuta el SQL, la app sigue funcionando (sin las políticas RLS)
- Se recomienda probar primero en un proyecto de Supabase de desarrollo/staging antes de aplicar a producción
- El script SQL usa `CREATE IF NOT EXISTS` para ser idempotente (se puede ejecutar varias veces sin errores)

## ✅ Checklist de Deployment

- [ ] Ejecutar `supabase/sql/profanity_and_blocking.sql` en Supabase
- [ ] Poblar `profanity_words` con palabras relevantes
- [ ] Agregar carga de `ProfanityFilter.instance.load()` en `main.dart`
- [ ] Actualizar `profanity_es.txt` con palabras específicas del contexto
- [ ] Probar en ambiente de desarrollo
- [ ] Documentar proceso de bloqueo en guías de usuario (si aplica)
- [ ] Merge del PR a `main`
