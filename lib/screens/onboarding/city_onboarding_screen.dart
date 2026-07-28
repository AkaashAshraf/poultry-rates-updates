import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/app_onboarding_content_model.dart';
import '../../providers/cities_provider.dart';
import '../../providers/city_preferences_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/city_multi_select.dart';
import '../../widgets/primary_button.dart';

/// Step 3 of the first-launch flow (language -> welcome -> city select ->
/// home), shown once on a fresh install. Lets the user choose which cities
/// they care about so those show first on the Rates tab and they get
/// notified when those cities' rates change. Also reachable later from
/// Settings > My Cities to change the selection.
class CityOnboardingScreen extends StatefulWidget {
  const CityOnboardingScreen({super.key});

  @override
  State<CityOnboardingScreen> createState() => _CityOnboardingScreenState();
}

class _CityOnboardingScreenState extends State<CityOnboardingScreen> {
  final Set<String> _selected = {};
  // Admin-editable description (same doc the welcome screen reads). Starts
  // null so the translated fallback shows immediately with no flicker,
  // then gets replaced once the fetch resolves, if the admin has set one.
  AppOnboardingContent? _content;

  @override
  void initState() {
    super.initState();
    context.read<FirestoreService>().fetchOnboardingContent().then((content) {
      if (!mounted) return;
      setState(() => _content = content);
    });
  }

  void _finish() {
    context.read<CityPreferencesProvider>().setPreferredCities(_selected.toList());
    context.go(AppRoutes.userHome);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cities = context.watch<CitiesProvider>().activeCities;
    final languageCode = context.locale.languageCode;
    final description = _content?.citySelectionDescription(languageCode);
    final subtitle = (description != null && description.isNotEmpty) ? description : 'onboarding.subtitle'.tr();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.location_city_rounded, color: AppColors.primary, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                'onboarding.title'.tr(),
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: SingleChildScrollView(
                  child: cities.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : CityMultiSelect(
                          cities: cities,
                          selectedIds: _selected,
                          languageCode: languageCode,
                          onToggle: (id) => setState(() {
                            _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
                          }),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: _selected.isEmpty ? 'onboarding.skip'.tr() : 'onboarding.continue'.tr(),
                onPressed: _finish,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
