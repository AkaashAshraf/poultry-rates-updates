import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/app_user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

enum AdminAuthStatus { unknown, signedOut, codeSent, verifying, authorized, notAuthorized }

/// Drives the whole admin login flow: send OTP -> confirm OTP -> check
/// allow-list -> authorized/not authorized. Also tracks whether the
/// *current* Firebase user (which could be an anonymous regular user) is
/// an authorized admin, which is what the router uses to guard /admin.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestoreService;

  AuthProvider(this._authService, this._firestoreService) {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  AdminAuthStatus status = AdminAuthStatus.unknown;
  bool isAdmin = false;
  String? errorMessage;
  String? _verificationId;
  int? _resendToken;
  String? pendingPhoneNumber;

  User? get firebaseUser => _authService.currentUser;

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      isAdmin = false;
      notifyListeners();
      return;
    }

    if (user.isAnonymous) {
      isAdmin = false;
    } else {
      // A non-anonymous user is signed in via phone auth — verify allow-list.
      final phone = user.phoneNumber;
      isAdmin = phone != null && await _authService.isAllowedAdmin(phone);
    }

    // Record/refresh this visitor in Firestore so the admin "Users" screen
    // has something to show. Fire-and-forget — never blocks the UI.
    unawaited(
      _firestoreService.upsertAppUser(
        AppUserModel(
          uid: user.uid,
          isAdmin: isAdmin,
          phoneNumber: user.phoneNumber,
        ),
      ),
    );

    notifyListeners();
  }

  Future<void> ensureAnonymousSession() => _authService.ensureAnonymousSession();

  Future<void> sendOtp(String e164Phone) async {
    status = AdminAuthStatus.verifying;
    errorMessage = null;
    pendingPhoneNumber = e164Phone;
    notifyListeners();

    await _authService.sendOtp(
      phoneNumber: e164Phone,
      forceResendingToken: _resendToken,
      onCodeSent: (verificationId, resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        status = AdminAuthStatus.codeSent;
        notifyListeners();
      },
      onFailed: (e) {
        errorMessage = e.message ?? 'auth.otpFailed';
        status = AdminAuthStatus.signedOut;
        notifyListeners();
      },
      onAutoVerified: (credential) async {
        try {
          await _authService.confirmOtp(
            verificationId: credential.verificationId ?? _verificationId ?? '',
            smsCode: '',
          );
        } catch (_) {
          // Auto-verification without manual code entry can fail silently on
          // some devices — the user can still enter the code manually.
        }
      },
    );
  }

  Future<bool> confirmOtp(String smsCode) async {
    if (_verificationId == null) return false;
    status = AdminAuthStatus.verifying;
    errorMessage = null;
    notifyListeners();

    try {
      final credential = await _authService.confirmOtp(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      final phone = credential.user?.phoneNumber;
      final allowed = phone != null && await _authService.isAllowedAdmin(phone);
      if (allowed) {
        isAdmin = true;
        status = AdminAuthStatus.authorized;
        notifyListeners();
        return true;
      } else {
        isAdmin = false;
        status = AdminAuthStatus.notAuthorized;
        errorMessage = 'auth.notAuthorized';
        await _authService.signOut();
        await _authService.ensureAnonymousSession();
        notifyListeners();
        return false;
      }
    } on FirebaseAuthException catch (e) {
      status = AdminAuthStatus.signedOut;
      errorMessage = e.message ?? 'auth.invalidCode';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOutAdmin() async {
    await _authService.signOut();
    isAdmin = false;
    status = AdminAuthStatus.signedOut;
    await _authService.ensureAnonymousSession();
    notifyListeners();
  }

  void resetFlow() {
    status = AdminAuthStatus.signedOut;
    errorMessage = null;
    _verificationId = null;
    pendingPhoneNumber = null;
    notifyListeners();
  }
}
