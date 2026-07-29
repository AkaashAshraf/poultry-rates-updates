/**
 * One-time migration: populates `currentRates/{cityId}_{category}` from
 * whatever's already in `rates`, so existing price history isn't lost when
 * the app switches from scanning full history to reading `currentRates`.
 * The syncCurrentRateOnWrite Cloud Function takes over from here for every
 * write after this runs — this script only needs to run once, before (or
 * right after) that function is deployed.
 *
 * Usage (from the functions/ directory):
 *   npm install                          # if you haven't already
 *   gcloud auth application-default login   # if not already logged in
 *   node scripts/backfill-current-rates.js
 *
 * Safe to re-run — it just recomputes and overwrites each currentRates doc.
 */
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

initializeApp();
const db = getFirestore();

async function main() {
  console.log('Reading all rates documents...');
  const ratesSnap = await db.collection('rates').get();
  console.log(`Found ${ratesSnap.size} rate documents.`);

  // Track the newest entry seen so far per "cityId_category" key.
  const latestByKey = new Map();

  for (const doc of ratesSnap.docs) {
    const data = doc.data();
    const { cityId, category, date } = data;
    if (!cityId || !category || !date) continue;

    const key = `${cityId}_${category}`;
    const existing = latestByKey.get(key);
    if (!existing || date.toMillis() > existing.date.toMillis()) {
      latestByKey.set(key, { id: doc.id, ...data });
    }
  }

  console.log(`Computed ${latestByKey.size} current-rate entries. Writing...`);

  let written = 0;
  const entries = Array.from(latestByKey.entries());
  // Batched in chunks of 400 (Firestore's batch limit is 500 writes).
  for (let i = 0; i < entries.length; i += 400) {
    const batch = db.batch();
    for (const [key, rate] of entries.slice(i, i + 400)) {
      const ref = db.collection('currentRates').doc(key);
      batch.set(ref, {
        category: rate.category,
        cityId: rate.cityId,
        cityNameEn: rate.cityNameEn || '',
        cityNameUr: rate.cityNameUr || '',
        price: rate.price,
        unit: rate.unit || '',
        date: rate.date,
        sourceRateId: rate.id,
      });
      written += 1;
    }
    await batch.commit();
    console.log(`  ...${written}/${entries.length} written`);
  }

  console.log('Done.');
}

main().catch((err) => {
  console.error('Backfill failed:', err);
  process.exit(1);
});
