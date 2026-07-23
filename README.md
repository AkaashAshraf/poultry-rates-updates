# Poultry Rates

A bilingual (English / Urdu) Flutter app for publishing daily poultry
market rates — chicken, meat and eggs — by city, with an admin panel
protected by Firebase phone/OTP login.

## What's inside

**Public app (no login required)**
- News feed
- Today's rates for chicken, meat and eggs, filterable by city
- Price trend graphs per city/category
- Settings: language (English/Urdu), light/dark theme, "Login as Admin"

**Admin panel** (phone number + OTP, allow-list protected)
- Dashboard: today's rates at a glance per city, tap to quick-update
- Cities: full CRUD
- Rates: full CRUD, tabbed by chicken / meat / egg, with price history
- Users: read-only list of app visitors

## Tech stack

Flutter 3.44 (pinned via FVM — see below), Firebase (Auth + Firestore),
Provider for state, go_router for navigation, easy_localization for
English/Urdu strings, fl_chart for the trend graphs, Material 3 theming
with a custom light/dark palette.

## Required Flutter version (FVM)

This project pins its Flutter version with [FVM](https://fvm.app) so
everyone on the team — and CI — builds with the exact same SDK. The
required version is declared in `.fvmrc`:

```json
{ "flutter": "3.44.7" }
```

Install FVM once, then let it install and switch to the pinned version:

```bash
dart pub global activate fvm
fvm install      # installs 3.44.7 if you don't already have it
fvm use          # links this project to that version (reads .fvmrc)
```

From here on, prefix every Flutter/Dart command with `fvm` so it always
runs against the pinned SDK instead of whatever global Flutter you have:

```bash
fvm flutter --version   # sanity check — should print 3.44.7
```

If you'd rather not install FVM, you can use your system Flutter directly
as long as it satisfies the constraint in `pubspec.yaml`
(`flutter: '>=3.44.0'`) — just drop the `fvm` prefix from every command
below.

## Getting started

```bash
fvm flutter pub get
```

Native Android/iOS project files were intentionally **not** hand-generated
(that's a risky thing to fake correctly for whatever Gradle/Xcode version
pairs with your pinned Flutter) — run this once to have Flutter generate
them for the exact SDK version from `.fvmrc`:

```bash
fvm flutter create --platforms=android,ios .
```

This only fills in missing native scaffolding; it will not touch anything
under `lib/`.

Then follow **FIREBASE_SETUP.md** to connect a Firebase project, enable
phone auth, deploy `firestore.rules`, and add your first admin phone
number.

Finally:

```bash
fvm flutter run
```

**IDE setup**: point Android Studio / VS Code at the FVM-managed SDK
instead of your global Flutter install, so in-editor run/debug also uses
3.44.7. In VS Code, run `fvm use` first (it writes `.vscode/settings.json`
automatically); in Android Studio, set the Flutter SDK path to
`.fvm/flutter_sdk` under **Settings > Languages & Frameworks > Flutter**.

## Project structure

```
lib/
  core/          theme, constants, routing, formatting helpers
  models/        City, Rate, AppUser, News
  services/      Firebase Auth + Firestore wrappers
  providers/     Provider ChangeNotifiers (auth, theme, cities, rates)
  screens/
    splash/
    auth/            admin phone login + OTP
    user/            feed, rates, graphs, settings (public)
    admin/           dashboard, cities, rates, users (protected)
  widgets/       shared UI (rate cards, empty states, dialogs, buttons)
assets/translations/  en.json, ur.json (easy_localization)
firestore.rules        security rules — deploy with `firebase deploy --only firestore:rules`
FIREBASE_SETUP.md       step-by-step Firebase configuration
.fvmrc                  pins the required Flutter version (3.44.7) for FVM
```

## Design notes

- **Color system**: deep teal/green primary (freshness, trust) with a
  warm amber accent, plus per-category tag colors (chicken = orange,
  meat = red, egg = golden yellow) so rate lists stay scannable at a
  glance. Full light and dark themes.
- **Typography**: Poppins for English, Noto Nastaliq Urdu for Urdu (real
  Nastaliq rendering, not a generic sans font), switched automatically
  based on the active language — including RTL layout for Urdu.
- **Price history, not overwrites**: every admin rate update creates a new
  Firestore document instead of overwriting the last one. That gives the
  trend graphs real historical data for free, and lets an admin delete a
  single bad entry without losing the rest of the history.
- **Admin security**: Firebase phone auth only proves phone ownership, not
  authorization — so admin access additionally requires the verified
  number to be on an `admins` allow-list in Firestore, managed from the
  console (never writable by the client). See `firestore.rules`.
- **Anonymous usage tracking**: regular users never see a login screen;
  they're silently signed in anonymously so the admin's "Users" screen
  has real numbers to show, without collecting any personal data.
# poultry-rates-updates
