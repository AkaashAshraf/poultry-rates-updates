import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';

class PoultryRatesApp extends StatelessWidget {
  const PoultryRatesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().mode;
    final languageCode = context.locale.languageCode;

    return MaterialApp.router(
      title: 'Poultry Hub',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      themeMode: themeMode,
      theme: AppTheme.light(languageCode),
      darkTheme: AppTheme.dark(languageCode),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}
