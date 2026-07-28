import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/cities_provider.dart';
import 'providers/city_preferences_provider.dart';
import 'providers/rates_provider.dart';
import 'providers/theme_provider.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/interstitial_ad_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Mobile already defaults to this, but it's set explicitly so offline
  // support is a documented, intentional choice rather than an SDK default
  // this app happens to rely on — every screen that reads via `.snapshots()`
  // (rates, cities, prefs) serves straight from this cache with no network,
  // and writes queue locally and sync once connectivity returns.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  await EasyLocalization.ensureInitialized();
  unawaited(MobileAds.instance.initialize());

  final authService = AuthService();
  final firestoreService = FirestoreService();
  final notificationService = NotificationService(firestoreService);
  final interstitialAdService = InterstitialAdService()..preload();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ur')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      child: MultiProvider(
        providers: [
          Provider<AuthService>.value(value: authService),
          Provider<FirestoreService>.value(value: firestoreService),
          Provider<NotificationService>.value(value: notificationService),
          Provider<InterstitialAdService>.value(value: interstitialAdService),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(
            create: (_) => AuthProvider(authService, firestoreService, notificationService),
          ),
          ChangeNotifierProvider(create: (_) => CitiesProvider(firestoreService)),
          ChangeNotifierProvider(create: (_) => RatesProvider(firestoreService)),
          ChangeNotifierProvider(create: (_) => CityPreferencesProvider(firestoreService, authService)),
        ],
        child: const PoultryRatesApp(),
      ),
    ),
  );
}
