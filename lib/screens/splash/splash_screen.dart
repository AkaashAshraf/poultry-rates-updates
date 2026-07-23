import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

/// Shown briefly on cold start while we silently sign the visitor in
/// anonymously (so the admin's "users" list has something to show) and
/// figure out whether they should land on the public app or, if they were
/// previously an authorized admin, straight into the admin panel.
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
    await authProvider.ensureAnonymousSession();
    // Give the auth-state listener a beat to resolve admin status.
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    if (authProvider.isAdmin) {
      context.go(AppRoutes.adminHome);
    } else {
      context.go(AppRoutes.userHome);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(Icons.egg_alt_rounded, color: Colors.white, size: 52),
              ),
              const SizedBox(height: 20),
              Text(
                'app.name'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'app.tagline'.tr(),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14),
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
