const { onDocumentCreated, onDocumentWritten } = require('firebase-functions/v2/firestore');
const { setGlobalOptions } = require('firebase-functions/v2');
const logger = require('firebase-functions/logger');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();
const db = getFirestore();
const messaging = getMessaging();

// Keep function instances (and cost) minimal — this fires at most a
// handful of times a day, whenever an admin saves a new rate.
setGlobalOptions({ maxInstances: 5, region: 'us-central1' });

const CATEGORY_LABELS = {
  chicken: { en: 'Chicken', ur: 'چکن' },
  meat: { en: 'Meat', ur: 'گوشت' },
  egg: { en: 'Eggs', ur: 'انڈے' },
};

/**
 * The Flutter app never overwrites a rate in place — every admin save
 * creates a brand-new `rates` document so the app keeps a full price
 * history (see lib/models/rate_model.dart). That means `onCreate` is the
 * only trigger we need: one new document == one new price == one
 * notification, sent to every user who's following that city.
 *
 * User docs store `preferredCityIds` (array of city IDs, written by
 * CityPreferencesProvider on the client) and `fcmToken` (written by
 * NotificationService). Both are merge-set fields on `users/{uid}`, one
 * doc per device.
 */
exports.notifyOnRateCreated = onDocumentCreated('rates/{rateId}', async (event) => {
  const rate = event.data?.data();
  if (!rate) return;

  const { cityId, category, cityNameEn, cityNameUr, price, unit } = rate;
  if (!cityId || !category) {
    logger.warn('Rate document missing cityId/category, skipping', { rateId: event.params.rateId });
    return;
  }

  const usersSnap = await db
    .collection('users')
    .where('preferredCityIds', 'array-contains', cityId)
    .get();

  if (usersSnap.empty) {
    logger.info('No followers for city, skipping', { cityId });
    return;
  }

  const tokens = usersSnap.docs
    .map((doc) => doc.data().fcmToken)
    .filter((token) => typeof token === 'string' && token.length > 0);

  if (tokens.length === 0) {
    logger.info('Followers found but none have a registered device token', { cityId });
    return;
  }

  const label = CATEGORY_LABELS[category] || { en: category, ur: category };
  const title = `${cityNameEn || ''} · ${label.en}`.trim();
  const body = `New rate: Rs. ${price} ${unit || ''}`.trim();

  // sendEachForMulticast caps at 500 tokens per call — chunk defensively
  // in case a single popular city ever exceeds that.
  const chunks = [];
  for (let i = 0; i < tokens.length; i += 500) {
    chunks.push(tokens.slice(i, i + 500));
  }

  const results = await Promise.all(
    chunks.map((chunk) =>
      messaging.sendEachForMulticast({
        tokens: chunk,
        notification: { title, body },
        data: {
          category,
          cityId,
          cityNameEn: cityNameEn || '',
          cityNameUr: cityNameUr || '',
        },
        android: { priority: 'high' },
        apns: { payload: { aps: { sound: 'default' } } },
      }),
    ),
  );

  const successCount = results.reduce((sum, r) => sum + r.successCount, 0);
  const failureCount = results.reduce((sum, r) => sum + r.failureCount, 0);
  logger.info('Rate notification sent', { cityId, category, successCount, failureCount });
});

/**
 * Keeps `currentRates/{cityId}_{category}` pointed at whichever `rates`
 * document is actually the newest for that city+category, any time a
 * `rates` doc is created, edited, or deleted.
 *
 * Why this exists: the client used to derive "today's rate per city" by
 * reading *every* historical rates doc for a category and picking the
 * newest per city on-device. That query's cost grows without bound as
 * price history accumulates — at 10k daily users it goes from fine to
 * genuinely expensive within months. `currentRates` is a small,
 * always-flat collection (one doc per city+category, never more) that the
 * app reads instead — see lib/services/firestore_service.dart
 * (watchCurrentRatesForCategory) and lib/providers/rates_provider.dart.
 *
 * Recomputing from a fresh query (rather than just trusting "the new doc
 * is newest") is what makes this correct for edits and deletes too: an
 * admin editing an old entry's price, or deleting the current newest
 * entry, both need `currentRates` to reflect whatever is *actually*
 * newest afterward, not just whatever was last written.
 */
exports.syncCurrentRateOnWrite = onDocumentWritten('rates/{rateId}', async (event) => {
  const after = event.data?.after?.exists ? event.data.after.data() : null;
  const before = event.data?.before?.exists ? event.data.before.data() : null;
  const source = after || before;
  if (!source) return;

  const { cityId, category } = source;
  if (!cityId || !category) {
    logger.warn('Rate document missing cityId/category, skipping sync', { rateId: event.params.rateId });
    return;
  }

  const currentRateRef = db.collection('currentRates').doc(`${cityId}_${category}`);

  const latestSnap = await db
    .collection('rates')
    .where('cityId', '==', cityId)
    .where('category', '==', category)
    .orderBy('date', 'desc')
    .limit(1)
    .get();

  if (latestSnap.empty) {
    // Every entry for this city+category was deleted.
    await currentRateRef.delete().catch(() => {});
    return;
  }

  const latest = latestSnap.docs[0].data();
  await currentRateRef.set({
    category: latest.category,
    cityId: latest.cityId,
    cityNameEn: latest.cityNameEn || '',
    cityNameUr: latest.cityNameUr || '',
    price: latest.price,
    unit: latest.unit || '',
    date: latest.date,
    sourceRateId: latestSnap.docs[0].id,
  });
});
