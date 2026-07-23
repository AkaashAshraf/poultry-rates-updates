// Android values below are real, taken from android/app/google-services.json
// (Firebase project "al-akbar-452b4", app poultry.hub.updates.customer).
// iOS is still a PLACEHOLDER — no iOS app has been registered/downloaded yet.
//
// The cleanest way to finish this file (and double-check the Android values
// too) is to run, from the project root:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// See FIREBASE_SETUP.md for the full step-by-step guide.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web — run `flutterfire configure`.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform — run `flutterfire configure`.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBoTId9_5BaN79rTZlWhgehR1gwyRYWm-4',
    appId: '1:258207594608:android:04eecb0c249bb015bf5cb5',
    messagingSenderId: '258207594608',
    projectId: 'al-akbar-452b4',
    storageBucket: 'al-akbar-452b4.firebasestorage.app',
  );

  // TODO: Replace with real values once the iOS app is registered — either
  // via the Firebase console (Add app > iOS) + downloading
  // GoogleService-Info.plist, or by running `flutterfire configure`.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'REPLACE_ME',
    storageBucket: 'REPLACE_ME.appspot.com',
    iosBundleId: 'poultry.hub.updates.customer',
  );
}
