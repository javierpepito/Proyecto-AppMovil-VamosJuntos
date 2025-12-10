# Sistema de Notificaciones Automáticas - VamosJuntos

Este sistema envía notificaciones push automáticamente a los usuarios de VamosJuntos cuando tienen salidas próximas.

## 🔄 Funcionamiento

- **Ejecución automática**: Cada 5 minutos vía GitHub Actions
- **Notificación 10 min antes**: Cuando faltan entre 8-12 minutos para la salida
- **Notificación al momento**: Cuando faltan entre -2 y +2 minutos (en el momento exacto)

## 🚀 Configuración en GitHub

### 1. Subir el código a GitHub

```bash
cd c:\Users\javie\OneDrive\Escritorio\Proyecto-AppMovil-VamosJuntos
git add .
git commit -m "Agregar sistema de notificaciones FCM"
git push origin main
```

### 2. Configurar Secrets en GitHub

Ve a tu repositorio en GitHub → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Agrega estos 3 secrets:

#### `SUPABASE_URL`
```
https://tu-proyecto.supabase.co
```

#### `SUPABASE_KEY`
```
Tu_Supabase_Anon_Key
```

#### `FIREBASE_SERVICE_ACCOUNT`
Copia TODO el contenido del archivo JSON que descargaste de Firebase (el service account):
```json
{
  "type": "service_account",
  "project_id": "vamosjuntos-7918e",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...",
  ...
}
```

### 3. Activar GitHub Actions

1. Ve a la pestaña **Actions** en tu repositorio
2. Si está desactivado, haz clic en "I understand my workflows, go ahead and enable them"
3. El workflow `send-notifications.yml` aparecerá en la lista

### 4. Probar manualmente

1. En la pestaña Actions, selecciona "Enviar Notificaciones FCM"
2. Haz clic en "Run workflow" → "Run workflow"
3. Revisa los logs para ver si funciona correctamente

## ✅ Ventajas

- ✅ **100% Gratis**: GitHub Actions da 2,000 minutos gratis/mes
- ✅ **Confiable**: Se ejecuta cada 5 minutos automáticamente
- ✅ **Exacto**: Notificaciones precisas con ventanas de tiempo
- ✅ **Sin servidor**: No necesitas pagar hosting
- ✅ **Logs completos**: Puedes ver qué notificaciones se envían

## 📊 Monitoreo

Cada ejecución genera logs que puedes ver en:
- GitHub → Actions → Workflow run → Send notifications

Los logs muestran:
- Cuántas participaciones se encontraron
- Qué notificaciones se enviaron
- A quién se enviaron
- Errores si los hay

## 🔧 Ajustes

Para cambiar la frecuencia de ejecución, edita `.github/workflows/send-notifications.yml`:

```yaml
schedule:
  - cron: '*/5 * * * *'  # Cada 5 minutos
  # - cron: '*/10 * * * *'  # Cada 10 minutos
  # - cron: '0 * * * *'     # Cada hora
```

## 🐛 Troubleshooting

Si las notificaciones no llegan:

1. Verifica que el token FCM esté guardado en la BD (tabla `usuarios`, columna `fcm_token`)
2. Revisa los logs en GitHub Actions
3. Verifica que la salida tenga `estado = 'abierta'`
4. Confirma que el usuario está en `salida_participantes`
5. Verifica que Firebase Cloud Messaging API (v1) esté habilitado

## 📱 Prueba

Para probar rápidamente:

1. Crea una salida con hora en 10 minutos
2. Únete a esa salida
3. Espera 5-10 minutos (siguiente ejecución de GitHub Actions)
4. O ejecuta manualmente el workflow desde GitHub Actions
5. Deberías recibir la notificación push
