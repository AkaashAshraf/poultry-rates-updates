import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/app_version_config_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/city_preferences_provider.dart';
import '../../services/firestore_service.dart';

/// Shown briefly on cold start while we silently sign the visitor in
/// anonymously (so the admin's "users" list has something to show),
/// enforce the force-update gate, and figure out whether they should land
/// on the public app, the first-launch onboarding flow, or — if they were
/// previously an authorized admin — straight into the admin panel.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final authProvider = context.read<AuthProvider>();
    final cityPrefs = context.read<CityPreferencesProvider>();
    final firestoreService = context.read<FirestoreService>();

    // Everything in here talks to the network in one way or another
    // (anonymous sign-in, the version-config fetch) except cityPrefs.ready,
    // which is local-only. ensureAnonymousSession/fetchVersionConfig are
    // both already offline-safe on their own (timeouts + no throw), but
    // this try/catch is a second line of defense: whatever happens, the
    // splash screen must still hand off to a route below rather than sit
    // on its spinner forever with no connectivity.
    var versionConfig = const AppVersionConfig();
    try {
      // Kicked off alongside the other two (not awaited yet) so it runs
      // concurrently — kept as its own future rather than thrown into the
      // same Future.wait list below, since mixing Future<void> with
      // Future<AppVersionConfig> in one list literal makes Dart infer an
      // awkward common type.
      final versionConfigFuture = firestoreService.fetchVersionConfig();
      await Future.wait([
        authProvider.ensureAnonymousSession(),
        cityPrefs.ready,
      ]);
      versionConfig = await versionConfigFuture;
      // Give the auth-state listener a beat to resolve admin status.
      await Future.delayed(const Duration(milliseconds: 900));
    } catch (e) {
      debugPrint('Splash bootstrap error, continuing offline: $e');
    }
    if (!mounted) return;

    // Force-update gate runs before anything else, admin included — a
    // build below the minimum should never get past this screen.
    final minBuild = Platform.isIOS ? versionConfig.minBuildNumberIos : versionConfig.minBuildNumberAndroid;
    if (minBuild > 0) {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;
      debugPrint(
        'Force-update check: installed build=$currentBuild, required minimum=$minBuild '
        '(${Platform.isIOS ? 'iOS' : 'Android'})',
      );
      if (currentBuild < minBuild) {
        if (!mounted) return;
        context.go(AppRoutes.forceUpdate, extra: versionConfig);
        return;
      }
    } else {
      debugPrint('Force-update check: gate disabled (minBuild is 0 for this platform)');
    }

    if (authProvider.isAdmin) {
      context.go(AppRoutes.adminHome);
    } else if (!cityPrefs.hasOnboarded) {
      context.go(AppRoutes.languageSelect);
    } else {
      context.go(AppRoutes.userHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    // This screen builds its own plain TextStyles instead of reading
    // Theme.of(context).textTheme, so it doesn't automatically pick up the
    // Urdu size scaling in AppTypography — sized by hand here instead.
    final isUrdu = context.locale.languageCode == 'ur';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.splashGradient,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'app.name'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isUrdu ? 18 : 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'app.tagline'.tr(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: isUrdu ? 11 : 14,
                ),
              ),
              const SizedBox(height: 36),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
