# Firebase setup

The app needs a Firebase project with **Phone Authentication** and **Cloud
Firestore** enabled. Do this once, before your first `fvm flutter run`
(see README.md for installing the pinned Flutter version with FVM first).

## 1. Create the Firebase project

1. Go to https://console.firebase.google.com and create a new project (or
   reuse an existing one).
2. In **Build > Authentication > Sign-in method**, enable **Phone**.
3. In **Build > Firestore Database**, click **Create database** and start
   in production mode (the rules shipped in `firestore.rules` will lock it
   down correctly).

## 2. Connect the Flutter app to Firebase

From the project root:

```bash
fvm dart pub global activate flutterfire_cli
firebase login
fvm flutter pub global run flutterfire_cli:flutterfire configure
```

(Running it via `fvm flutter pub global run ...` makes sure the CLI acts
against the pinned SDK. If you have `flutterfire` on your PATH already,
plain `flutterfire configure` works too.)

Pick your Firebase project and the platforms you want (Android/iOS). This
regenerates `lib/firebase_options.dart` with real values (the one currently
in the repo is a placeholder) and adds `google-services.json` /
`GoogleService-Info.plist` automatically.

## 3. Android: SHA-1/SHA-256 fingerprints

Phone auth on Android needs your app's signing fingerprints registered:

```bash
cd android && ./gradlew signingReport
```

Copy the SHA-1 and SHA-256 for the `debug` (and later `release`) variant
into **Project settings > Your apps > Android app** in the Firebase
console.

## 4. iOS: enable silent push for phone auth

In the Firebase console, under **Authentication > Sign-in method > Phone**,
upload your APNs authentication key (Apple Developer account required).
Without this, Firebase falls back to reCAPTCHA verification on iOS, which
still works but is a worse user experience.

## 5. Deploy Firestore security rules

```bash
firebase deploy --only firestore:rules
```

(`firestore.rules` is already in the project root, ready to deploy.)

## 6. Add your first admin

Regular admin access is allow-list based: a phone auth login only succeeds
in reaching the admin panel if the verified phone number also exists in
the `admins` Firestore collection. To add yourself:

1. Open **Firestore Database** in the console.
2. Create a collection named `admins`.
3. Add a document whose **document ID** is your phone number in E.164
   format, e.g. `+923001234567`.
4. Give it one field: `isActive` (boolean) = `true`.

Now, in the app, go to **Settings > Login as Admin**, enter that phone
number, and complete the OTP flow — you'll land in the admin panel.

## 7. Seed a city and a news post (optional, but recommended)

The app works with zero seed data (empty states guide the admin), but to
see it fully populated, add via the console:

**`cities` collection**, one document per city:
```json
{ "nameEn": "Lahore", "nameUr": "لاہور", "isActive": true }
```

**`news` collection**, one document per post:
```json
{
  "titleEn": "Welcome",
  "titleUr": "خوش آمدید",
  "bodyEn": "Daily poultry rates, now in one place.",
  "bodyUr": "روزانہ پولٹری کے نرخ، اب ایک ہی جگہ۔",
  "createdAt": <Firestore timestamp, now>
}
```

Once a city exists, use the admin Dashboard tab to add chicken/meat/egg
rates for it — every save creates a new price-history entry, which is
what powers the trend graphs in the user app.

## 8. Push notifications (Cloud Functions)

Users pick which cities to follow (on first launch, and any time after in
Settings > My Cities). When an admin saves a new rate for a followed city,
everyone following it gets a push notification. This is driven by a Cloud
Function (`functions/`) that triggers on every new `rates` document.

**This requires the Blaze (pay-as-you-go) plan** — Cloud Functions with
Firestore triggers aren't available on the free Spark plan. Blaze still has
a generous free tier (2M function invocations/month); for an app this size
you're extremely unlikely to be charged anything. Upgrade at
**Firebase console > (bottom left) Upgrade project**.

Once you're on Blaze:

```bash
cd functions && npm install
cd ..
firebase deploy --only functions
```

That deploys two functions:

1. **`notifyOnRateCreated`** — watches `rates/{rateId}` for new documents,
   looks up which users have that rate's `cityId` in their
   `preferredCityIds` array, and pushes to their registered `fcmToken`s.
2. **`syncCurrentRateOnWrite`** — keeps a small `currentRates` collection
   (one doc per city+category) pointed at whichever `rates` entry is
   currently newest. The app reads `currentRates` instead of scanning the
   full `rates` history to figure out "today's price" — important once you
   have real usage, since the old approach's read cost grew without bound
   as price history piled up.

**One-time step after your first deploy:** `syncCurrentRateOnWrite` only
keeps `currentRates` in sync for writes that happen *after* it's deployed.
Backfill it once from whatever's already in `rates`:

```bash
cd functions
gcloud auth application-default login   # if you haven't already
node scripts/backfill-current-rates.js
```

Safe to re-run if needed — it just recomputes and overwrites.

No further console setup is needed for Android — Firebase Cloud Messaging
works automatically once google-services.json is in place. **For iOS**,
push notifications need an APNs authentication key uploaded under
**Project settings > Cloud Messaging** (the same key from step 4 covers
both phone-auth silent push and regular notifications), plus the "Push
Notifications" and "Background Modes > Remote notifications" capabilities
enabled in Xcode for the Runner target.
