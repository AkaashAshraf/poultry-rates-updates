import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/routing/app_router.dart';
import '../../models/app_onboarding_content_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/primary_button.dart';

/// Step 2 of the first-launch flow. Title/message are admin-editable
/// (Firestore `appConfig/onboarding`, edited from the admin panel's App
/// Content screen) so the app owner can change the pitch without a store
/// release. Falls back to a translated default if the admin hasn't set
/// anything yet.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final Future<AppOnboardingContent> _contentFuture;

  @override
  void initState() {
    super.initState();
    _contentFuture = context.read<FirestoreService>().fetchOnboardingContent();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final languageCode = context.locale.languageCode;

    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<AppOnboardingContent>(
          future: _contentFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final content = snapshot.data ?? const AppOnboardingContent();
            final title = content.welcomeTitle(languageCode).isNotEmpty
                ? content.welcomeTitle(languageCode)
                : 'welcome.title'.tr();
            final message = content.welcomeMessage(languageCode).isNotEmpty
                ? content.welcomeMessage(languageCode)
                : 'welcome.subtitle'.tr();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        message,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  PrimaryButton(
                    label: 'onboarding.continue'.tr(),
                    onPressed: () => context.go(AppRoutes.cityOnboarding),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
