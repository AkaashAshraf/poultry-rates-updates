import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../models/app_version_config_model.dart';
import '../../widgets/primary_button.dart';

/// Blocking "please update" screen. Shown by SplashScreen instead of the
/// normal app when the installed build number is below whatever the
/// developer set in Firestore `appConfig/version` — see
/// AppVersionConfig's doc comment for how to configure that.
///
/// Deliberately has no way out: no back button (PopScope blocks both the
/// AppBar back arrow — there isn't one — and the system back
/// gesture/button), no skip action. The only path forward is updating.
class ForceUpdateScreen extends StatelessWidget {
  final AppVersionConfig config;

  const ForceUpdateScreen({super.key, required this.config});

  Future<void> _openStore() async {
    final url = Platform.isIOS ? config.appStoreUrl : config.playStoreUrl;
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final languageCode = context.locale.languageCode;
    final message = config.updateMessage(languageCode).isNotEmpty
        ? config.updateMessage(languageCode)
        : 'forceUpdate.subtitle'.tr();

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.system_update_rounded, color: AppColors.primary, size: 40),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'forceUpdate.title'.tr(),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    label: 'forceUpdate.updateNow'.tr(),
                    icon: Icons.system_update_rounded,
                    onPressed: _openStore,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
