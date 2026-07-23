import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/cities_provider.dart';
import 'providers/rates_provider.dart';
import 'providers/theme_provider.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await EasyLocalization.ensureInitialized();

  final authService = AuthService();
  final firestoreService = FirestoreService();

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
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider(authService, firestoreService)),
          ChangeNotifierProvider(create: (_) => CitiesProvider(firestoreService)),
          ChangeNotifierProvider(create: (_) => RatesProvider(firestoreService)),
        ],
        child: const PoultryRatesApp(),
      ),
    ),
  );
}
