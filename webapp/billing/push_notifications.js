/**
 * Lexend Scholar — Push Notifications via Firebase Cloud Messaging
 * (Server-side: Node.js usando firebase-admin SDK)
 *
 * Dependências:
 *   npm install firebase-admin
 *
 * Variáveis de ambiente:
 *   FIREBASE_PROJECT_ID
 *   FIREBASE_CLIENT_EMAIL
 *   FIREBASE_PRIVATE_KEY      (string com \n)
 *
 * Tabelas usadas (database_schema.sql):
 *   users.fcm_token            — token FCM por usuário
 *   push_notification_log      — log de envios
 */

import { initializeApp, getApps, cert } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import { createClient } from '@supabase/supabase-js';

// ---------------------------------------------------------------------------
// Firebase Admin initialization (singleton)
// ---------------------------------------------------------------------------
function getFirebaseApp() {
  if (getApps().length > 0) return getApps()[0];

  return initializeApp({
    credential: cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    }),
  });
}

function getSupabase() {
  return createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_KEY);
}

// ---------------------------------------------------------------------------
// NOTIFICATION TEMPLATES
// Tipos de notificação Lexend Scholar
// ---------------------------------------------------------------------------
export const NOTIFICATION_TYPES = {
  ATTENDANCE_ABSENT: 'attendance_absent',
  GRADE_RELEASED: 'grade_released',
  FINANCIAL_DUE: 'financial_due',
  FINANCIAL_OVERDUE: 'financial_overdue',
  ANNOUNCEMENT: 'announcement',
  TRIAL_EXPIRING: 'trial_expiring',
};

const templates = {
  [NOTIFICATION_TYPES.ATTENDANCE_ABSENT]: (data) => ({
    title: `Falta registrada — ${data.studentName}`,
    body: `${data.studentName} teve falta registrada em ${data.subject} em ${data.date}.`,
  }),
  [NOTIFICATION_TYPES.GRADE_RELEASED]: (data) => ({
    title: `Nova nota disponível — ${data.studentName}`,
    body: `Nota de ${data.subject}: ${data.score}/${data.maxScore}. Acesse o boletim para detalhes.`,
  }),
  [NOTIFICATION_TYPES.FINANCIAL_DUE]: (data) => ({
    title: 'Mensalidade com vencimento próximo',
    body: `A mensalidade de ${data.studentName} vence em ${data.dueDate}. Valor: ${data.amount}.`,
  }),
  [NOTIFICATION_TYPES.FINANCIAL_OVERDUE]: (data) => ({
    title: '⚠️ Mensalidade em atraso',
    body: `A mensalidade de ${data.studentName} está em atraso há ${data.daysOverdue} dias. Regularize para evitar bloqueio.`,
  }),
  [NOTIFICATION_TYPES.ANNOUNCEMENT]: (data) => ({
    title: data.title,
    body: data.body,
  }),
  [NOTIFICATION_TYPES.TRIAL_EXPIRING]: (data) => ({
    title: 'Seu trial Lexend Scholar expira em breve',
    body: `Restam ${data.daysRemaining} dia(s) de trial gratuito. Assine agora para não perder o acesso.`,
  }),
};

// ---------------------------------------------------------------------------
// sendPushToUser
// Envia notificação para um usuário específico via FCM token.
// ---------------------------------------------------------------------------
export async function sendPushToUser({ userId, type, data, schoolId }) {
  const supabase = getSupabase();

  const { data: user } = await supabase
    .from('users')
    .select('id, fcm_token, full_name')
    .eq('id', userId)
    .single();

  if (!user?.fcm_token) {
    console.warn(`[FCM] No FCM token for user ${userId}`);
    return null;
  }

  return sendPushToToken({ token: user.fcm_token, type, data, userId, schoolId });
}

// ---------------------------------------------------------------------------
// sendPushToSchool
// Envia para todos os usuários de uma escola com FCM token registrado.
// ---------------------------------------------------------------------------
export async function sendPushToSchool({ schoolId, type, data, roles }) {
  const supabase = getSupabase();

  let query = supabase
    .from('users')
    .select('id, fcm_token')
    .eq('school_id', schoolId)
    .eq('active', true)
    .not('fcm_token', 'is', null);

  if (roles?.length) {
    query = query.in('role', roles);
  }

  const { data: users } = await query;
  if (!users?.length) return { sent: 0, failed: 0 };

  const tokens = users.map(u => u.fcm_token);
  return sendPushMulticast({ tokens, type, data, schoolId });
}

// ---------------------------------------------------------------------------
// sendPushToToken (internal)
// ---------------------------------------------------------------------------
async function sendPushToToken({ token, type, data, userId, schoolId }) {
  const app = getFirebaseApp();
  const messaging = getMessaging(app);
  const template = templates[type];

  if (!template) throw new Error(`Unknown notification type: ${type}`);
  const { title, body } = template(data);

  const message = {
    token,
    notification: { title, body },
    data: {
      type,
      schoolId: schoolId || '',
      ...Object.fromEntries(
        Object.entries(data || {}).map(([k, v]) => [k, String(v)])
      ),
    },
    android: {
      notification: {
        channelId: 'lexend_scholar_default',
        priority: 'high',
        sound: 'default',
      },
    },
    apns: {
      payload: {
        aps: { sound: 'default', badge: 1 },
      },
    },
  };

  const supabase = getSupabase();
  let fcmMessageId = null;
  let error = null;

  try {
    const response = await messaging.send(message);
    fcmMessageId = response;
  } catch (err) {
    error = err.message;
    // Remove invalid token from DB
    if (err.code === 'messaging/registration-token-not-registered') {
      await supabase
        .from('users')
        .update({ fcm_token: null })
        .eq('fcm_token', token);
    }
    console.error(`[FCM] Send failed for token ${token.slice(0, 12)}...:`, err.message);
  }

  // Log attempt
  await supabase.from('push_notification_log').insert({
    school_id: schoolId,
    user_id: userId || null,
    title,
    body,
    data: { type, ...data },
    fcm_message_id: fcmMessageId,
    error,
  });

  return { success: !error, fcmMessageId, error };
}

// ---------------------------------------------------------------------------
// sendPushMulticast (internal) — batch up to 500 tokens
// ---------------------------------------------------------------------------
async function sendPushMulticast({ tokens, type, data, schoolId }) {
  const app = getFirebaseApp();
  const messaging = getMessaging(app);
  const template = templates[type];
  if (!template) throw new Error(`Unknown notification type: ${type}`);
  const { title, body } = template(data);

  const supabase = getSupabase();
  let totalSent = 0;
  let totalFailed = 0;

  // FCM multicast batch size limit = 500
  for (let i = 0; i < tokens.length; i += 500) {
    const batch = tokens.slice(i, i + 500);
    const message = {
      tokens: batch,
      notification: { title, body },
      data: {
        type,
        schoolId: schoolId || '',
        ...Object.fromEntries(Object.entries(data || {}).map(([k, v]) => [k, String(v)])),
      },
      android: { notification: { channelId: 'lexend_scholar_default', priority: 'high' } },
      apns: { payload: { aps: { sound: 'default' } } },
    };

    try {
      const response = await messaging.sendEachForMulticast(message);
      totalSent += response.successCount;
      totalFailed += response.failureCount;

      // Clean up invalid tokens
      const invalidTokens = response.responses
        .map((r, idx) => (!r.success && r.error?.code === 'messaging/registration-token-not-registered' ? batch[idx] : null))
        .filter(Boolean);

      if (invalidTokens.length) {
        await supabase.from('users').update({ fcm_token: null }).in('fcm_token', invalidTokens);
      }
    } catch (err) {
      console.error('[FCM] Multicast error:', err.message);
      totalFailed += batch.length;
    }
  }

  // Log summary
  await supabase.from('push_notification_log').insert({
    school_id: schoolId,
    title,
    body,
    data: { type, recipientCount: tokens.length, sent: totalSent, failed: totalFailed },
  });

  return { sent: totalSent, failed: totalFailed };
}

// ---------------------------------------------------------------------------
// registerFcmToken
// API endpoint helper — salva token FCM do dispositivo do usuário.
// ---------------------------------------------------------------------------
export async function registerFcmToken(userId, fcmToken) {
  const supabase = getSupabase();
  const { error } = await supabase
    .from('users')
    .update({ fcm_token: fcmToken, updated_at: new Date().toISOString() })
    .eq('id', userId);

  if (error) throw new Error(`registerFcmToken failed: ${error.message}`);
  return { success: true };
}
