const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();

const ANDROID_CHANNEL_ID = 'revolve_agro_updates';
const ADMINS_TOPIC = 'revolveagro_admins';

function currency(value) {
  const n = Number(value);
  if (Number.isFinite(n)) return `₹${Math.round(n)}`;
  return '';
}

async function getUserTokens(userId) {
  if (!userId) return [];
  const snap = await db.collection('users').doc(userId).collection('fcmTokens').get();
  return snap.docs.map((d) => d.id).filter(Boolean);
}

async function cleanupBadTokens(userId, tokens, responses) {
  if (!userId || !tokens?.length || !responses?.length) return;
  const batch = db.batch();
  let changed = false;

  for (let i = 0; i < responses.length; i++) {
    const r = responses[i];
    if (r.success) continue;
    const code = r.error?.code || '';
    const isBad =
      code === 'messaging/invalid-registration-token' ||
      code === 'messaging/registration-token-not-registered';
    if (!isBad) continue;
    const token = tokens[i];
    if (!token) continue;
    const ref = db.collection('users').doc(userId).collection('fcmTokens').doc(token);
    batch.delete(ref);
    changed = true;
  }

  if (changed) {
    await batch.commit();
  }
}

async function sendToUser(userId, { title, body, data }) {
  const tokens = await getUserTokens(userId);
  if (!tokens.length) return;

  const message = {
    tokens,
    notification: { title, body },
    data: data || {},
    android: {
      priority: 'high',
      notification: {
        channelId: ANDROID_CHANNEL_ID,
        sound: 'default'
      }
    },
    apns: {
      payload: {
        aps: {
          sound: 'default'
        }
      }
    }
  };

  const resp = await admin.messaging().sendMulticast(message);
  await cleanupBadTokens(userId, tokens, resp.responses);
}

async function sendToTopic(topic, { title, body, data }) {
  if (!topic) return;
  await admin.messaging().send({
    topic,
    notification: { title, body },
    data: data || {},
    android: {
      priority: 'high',
      notification: {
        channelId: ANDROID_CHANNEL_ID,
        sound: 'default'
      }
    },
    apns: {
      payload: {
        aps: {
          sound: 'default'
        }
      }
    }
  });
}

exports.notifyOnOrderCreated = functions.firestore
  .document('orders/{orderId}')
  .onCreate(async (snap, context) => {
    const orderId = context.params.orderId;
    const order = snap.data() || {};
    const userId = order.userId;
    const userName = order.userName || 'Customer';
    const total = currency(order.totalAmount ?? order.subtotal);

    await Promise.allSettled([
      sendToUser(userId, {
        title: 'Order received',
        body: `Thanks ${userName}. We received your order ${total ? `(${total})` : ''}.`,
        data: {
          type: 'order_created',
          orderId: String(orderId)
        }
      }),
      sendToTopic(ADMINS_TOPIC, {
        title: 'New order',
        body: `${userName} placed a new order ${total ? `(${total})` : ''}.`,
        data: {
          type: 'admin_order_created',
          orderId: String(orderId),
          userId: userId ? String(userId) : ''
        }
      })
    ]);
  });

exports.notifyOnOrderStatusChanged = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data() || {};
    const after = change.after.data() || {};
    const orderId = context.params.orderId;

    const beforeStatus = before.status || '';
    const afterStatus = after.status || '';
    const beforeTrack = before.trackingStatus || '';
    const afterTrack = after.trackingStatus || '';

    if (beforeStatus === afterStatus && beforeTrack === afterTrack) {
      return;
    }

    const userId = after.userId;
    const userName = after.userName || 'Customer';

    const changes = [];
    if (beforeStatus !== afterStatus && afterStatus) {
      changes.push(`status: ${afterStatus}`);
    }
    if (beforeTrack !== afterTrack && afterTrack) {
      changes.push(`tracking: ${afterTrack}`);
    }

    const body = changes.length
      ? `Your order update (${changes.join(', ')}).`
      : 'Your order has an update.';

    await sendToUser(userId, {
      title: 'Order update',
      body,
      data: {
        type: 'order_updated',
        orderId: String(orderId),
        status: afterStatus ? String(afterStatus) : '',
        trackingStatus: afterTrack ? String(afterTrack) : ''
      }
    });

    // Notify admins too, but only when status changes.
    if (beforeStatus !== afterStatus && afterStatus) {
      await sendToTopic(ADMINS_TOPIC, {
        title: 'Order status changed',
        body: `${userName}'s order is now ${afterStatus}.`,
        data: {
          type: 'admin_order_status_changed',
          orderId: String(orderId),
          status: String(afterStatus),
          userId: userId ? String(userId) : ''
        }
      });
    }
  });

