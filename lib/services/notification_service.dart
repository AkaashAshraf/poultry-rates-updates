import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'firestore_service.dart';

/// Wraps Firebase Cloud Messaging: requests notification permission and
/// keeps the current device's token in sync with its Firestore user doc,
/// so the notify-on-rate-update Cloud Function knows where to deliver a
/// push. One token per signed-in uid — consistent with the "one user = one
/// device" model the rest of the app uses (regular users are only ever
/// signed in anonymously, one Firebase user per install).
class NotificationService {
  final FirestoreService _firestoreService;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  NotificationService(this._firestoreService);

  String? _initializedForUid;

  /// Safe to call every time auth state resolves to a user — it's a no-op
  /// if already initialized for this exact uid.
  Future<void> initialize(String uid) async {
    if (_initializedForUid == uid) return;
    _initializedForUid = uid;

    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('Notifications: permission denied by user.');
        return;
      }

      final token = await _messaging.getToken();
      if (token != null) {
        await _firestoreService.updateFcmToken(uid, token);
      }

      _messaging.onTokenRefresh.listen((newToken) {
        _firestoreService.updateFcmToken(uid, newToken);
      });

      // The app is already open when this fires, so there's no native
      // heads-up banner without extra plugin/platform-channel setup
      // (flutter_local_notifications). Background/terminated delivery
      // works out of the box via the OS notification tray since the
      // Cloud Function sends a display `notification` payload.
      FirebaseMessaging.onMessage.listen((message) {
        debugPrint(
          'Foreground FCM message: ${message.notification?.title} — ${message.notification?.body}',
        );
      });
    } catch (e) {
      // Notifications are a nice-to-have, not something that should ever
      // block the rest of the app from working.
      debugPrint('NotificationService.initialize failed: $e');
    }
  }
}
