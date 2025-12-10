const admin = require('firebase-admin');
const { createClient } = require('@supabase/supabase-js');

// Inicializar Firebase Admin con Service Account desde variable de entorno
const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT || '{}');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// Inicializar Supabase
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_KEY
);

// Registro de notificaciones enviadas (en memoria, se resetea cada ejecución)
const notificacionesEnviadas = new Set();

async function enviarNotificaciones() {
  console.log('═══════════════════════════════════════════════');
  console.log('🔄 INICIANDO ENVÍO DE NOTIFICACIONES');
  console.log(`   Hora: ${new Date().toLocaleString('es-CL', { timeZone: 'America/Santiago' })}`);
  console.log('═══════════════════════════════════════════════\n');

  try {
    const ahora = new Date();
    const en8Min = new Date(ahora.getTime() + 8 * 60000);
    const en12Min = new Date(ahora.getTime() + 12 * 60000);
    const hace2Min = new Date(ahora.getTime() - 2 * 60000);
    const en2Min = new Date(ahora.getTime() + 2 * 60000);

    // Obtener salidas próximas con sus participantes
    const { data: participaciones, error } = await supabase
      .from('salida_participantes')
      .select(`
        salida_id,
        usuario_id,
        salidas!inner(
          id,
          hora_salida,
          punto_encuentro,
          estado
        ),
        usuarios!inner(
          id,
          fcm_token,
          nombre
        )
      `)
      .eq('salidas.estado', 'abierta')
      .not('usuarios.fcm_token', 'is', null);

    if (error) {
      console.error('❌ Error consultando Supabase:', error);
      return;
    }

    console.log(`📊 Participaciones encontradas: ${participaciones?.length || 0}\n`);

    let notif10MinEnviadas = 0;
    let notifMomentoEnviadas = 0;

    for (const participacion of participaciones || []) {
      const salida = participacion.salidas;
      const usuario = participacion.usuarios;
      const horaSalida = new Date(salida.hora_salida);
      const diffMinutos = (horaSalida - ahora) / 60000;

      const key10 = `10min_${usuario.id}_${salida.id}`;
      const keyMomento = `momento_${usuario.id}_${salida.id}`;

      // Notificación 10 minutos antes (ventana: 8-12 min)
      if (diffMinutos >= 8 && diffMinutos <= 12 && !notificacionesEnviadas.has(key10)) {
        try {
          await admin.messaging().send({
            token: usuario.fcm_token,
            notification: {
              title: '🚌 ¡Tu salida es en 10 minutos!',
              body: `Punto de encuentro: ${salida.punto_encuentro}`
            },
            data: {
              salida_id: salida.id,
              tipo: '10min',
              punto_encuentro: salida.punto_encuentro,
              hora_salida: salida.hora_salida
            },
            android: {
              priority: 'high',
              notification: {
                channelId: 'salidas_channel',
                priority: 'max',
                sound: 'default'
              }
            }
          });

          notificacionesEnviadas.add(key10);
          notif10MinEnviadas++;
          console.log(`✅ Notif 10min enviada → ${usuario.nombre || usuario.id.substring(0, 8)}`);
          console.log(`   Salida: ${salida.punto_encuentro} a las ${new Date(salida.hora_salida).toLocaleTimeString('es-CL', { hour: '2-digit', minute: '2-digit' })}\n`);
        } catch (err) {
          console.error(`❌ Error enviando notif 10min a ${usuario.id}:`, err.message);
        }
      }

      // Notificación al momento (ventana: -2 a +2 min)
      if (diffMinutos >= -2 && diffMinutos <= 2 && !notificacionesEnviadas.has(keyMomento)) {
        try {
          await admin.messaging().send({
            token: usuario.fcm_token,
            notification: {
              title: '🚀 ¡Es hora de partir!',
              body: `Tu salida desde ${salida.punto_encuentro} comienza ahora`
            },
            data: {
              salida_id: salida.id,
              tipo: 'momento',
              punto_encuentro: salida.punto_encuentro,
              hora_salida: salida.hora_salida
            },
            android: {
              priority: 'high',
              notification: {
                channelId: 'salidas_channel',
                priority: 'max',
                sound: 'default'
              }
            }
          });

          notificacionesEnviadas.add(keyMomento);
          notifMomentoEnviadas++;
          console.log(`✅ Notif MOMENTO enviada → ${usuario.nombre || usuario.id.substring(0, 8)}`);
          console.log(`   Salida: ${salida.punto_encuentro}\n`);
        } catch (err) {
          console.error(`❌ Error enviando notif momento a ${usuario.id}:`, err.message);
        }
      }
    }

    console.log('═══════════════════════════════════════════════');
    console.log('✅ PROCESO COMPLETADO');
    console.log(`   Notificaciones 10 min: ${notif10MinEnviadas}`);
    console.log(`   Notificaciones momento: ${notifMomentoEnviadas}`);
    console.log(`   Total enviadas: ${notif10MinEnviadas + notifMomentoEnviadas}`);
    console.log('═══════════════════════════════════════════════');

  } catch (error) {
    console.error('\n❌❌❌ ERROR FATAL ❌❌❌');
    console.error(error);
    process.exit(1);
  }
}

// Ejecutar
enviarNotificaciones()
  .then(() => {
    console.log('\n✅ Script finalizado correctamente');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Script finalizado con error:', error);
    process.exit(1);
  });
