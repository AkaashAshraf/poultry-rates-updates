import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/primary_button.dart';

/// Step 1 of the first-launch flow (language -> welcome -> city select ->
/// home). Only ever shown once — after this, language lives in Settings.
///
/// Preselects English or Urdu based on the device's own locale so most
/// users can just tap Continue, while still letting them pick the other
/// language explicitly.
class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    final deviceLanguage = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    _selected = deviceLanguage == 'ur' ? 'ur' : 'en';
  }

  void _continue() {
    context.setLocale(Locale(_selected));
    context.go(AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.translate_rounded, color: AppColors.primary, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                'languageSelect.title'.tr(),
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'languageSelect.subtitle'.tr(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 32),
              _LanguageCard(
                nativeLabel: 'English',
                selected: _selected == 'en',
                onTap: () => setState(() => _selected = 'en'),
              ),
              const SizedBox(height: 14),
              _LanguageCard(
                nativeLabel: 'اردو',
                selected: _selected == 'ur',
                onTap: () => setState(() => _selected = 'ur'),
              ),
              const Spacer(),
              PrimaryButton(label: 'onboarding.continue'.tr(), onPressed: _continue),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String nativeLabel;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.nativeLabel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.08) : theme.colorScheme.surface,
          border: Border.all(
            color: selected ? AppColors.primary : theme.colorScheme.outlineVariant,
            width: selected ? 1.6 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : theme.colorScheme.outline,
            ),
            const SizedBox(width: 14),
            Text(
              nativeLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
