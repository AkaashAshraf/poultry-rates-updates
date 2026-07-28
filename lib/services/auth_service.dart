import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/app_constants.dart';

/// Wraps Firebase phone-auth OTP flow and the admin allow-list check.
///
/// Security model: Firebase phone auth only proves the caller owns a phone
/// number — it does NOT by itself mean that person should get admin access.
/// So after a successful OTP verification we check the verified phone
/// number against the `admins` Firestore collection (pre-populated by the
/// app owner). Only allow-listed numbers are granted admin access; anyone
/// else is immediately signed back out.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Signs regular (non-admin) users in anonymously so the admin can see
  /// aggregate usage in the "Users" screen. Silent — no UI is shown.
  ///
  /// Once a device has signed in anonymously at least once, Firebase Auth
  /// caches that session locally and [_auth.currentUser] is non-null on
  /// every later launch — network or not. It's only a *first* launch with
  /// no connectivity that reaches the network call below, and that call
  /// must never be allowed to block app startup: bounded by a short
  /// timeout and never throws, so a splash screen awaiting this always
  /// moves on. The rest of the app treats "no user yet" the same as
  /// "anonymous, not admin", and a session is established the next time
  /// this runs with connectivity.
  Future<User?> ensureAnonymousSession() async {
    final existing = _auth.currentUser;
    if (existing != null) return existing;
    try {
      final credential = await _auth.signInAnonymously().timeout(const Duration(seconds: 8));
      return credential.user;
    } catch (_) {
      return null;
    }
  }

  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(FirebaseAuthException error) onFailed,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
    int? forceResendingToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      forceResendingToken: forceResendingToken,
      verificationCompleted: onAutoVerified,
      verificationFailed: onFailed,
      codeSent: (verificationId, resendToken) => onCodeSent(verificationId, resendToken),
      codeAutoRetrievalTimeout: (verificationId) {},
    );
  }

  Future<UserCredential> confirmOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _auth.signInWithCredential(credential);
  }

  /// Returns true if [phoneNumber] (E.164 format, e.g. +923001234567) is on
  /// the admin allow-list.
  Future<bool> isAllowedAdmin(String phoneNumber) async {
    final doc = await _firestore.collection(FirestoreCollections.admins).doc(phoneNumber).get();
    return doc.exists && (doc.data()?['isActive'] as bool? ?? true);
  }

  Future<void> signOut() => _auth.signOut();
}
