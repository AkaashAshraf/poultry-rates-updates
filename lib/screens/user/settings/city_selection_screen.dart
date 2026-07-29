import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/cities_provider.dart';
import '../../../providers/city_preferences_provider.dart';
import '../../../widgets/city_multi_select.dart';

/// Dedicated city picker. Reached from Settings > My Cities and from the
/// Rates tab's "no followed cities" empty state, so both entry points land
/// on the exact same editor instead of one being a shortcut into a
/// different UI. Toggling a chip saves immediately via
/// [CityPreferencesProvider] — there's no separate save step.
class CitySelectionScreen extends StatelessWidget {
  const CitySelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cities = context.watch<CitiesProvider>().activeCities;
    final cityPrefs = context.watch<CityPreferencesProvider>();
    final languageCode = context.locale.languageCode;

    return Scaffold(
      appBar: AppBar(title: Text('settings.myCities'.tr())),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'settings.myCitiesSubtitle'.tr(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: cities.isEmpty
                    ? Center(
                        child: Text(
                          'settings.myCitiesEmpty'.tr(),
                          style: theme.textTheme.bodySmall,
                        ),
                      )
                    : SingleChildScrollView(
                        child: CityMultiSelect(
                          cities: cities,
                          selectedIds: cityPrefs.preferredCityIds.toSet(),
                          languageCode: languageCode,
                          onToggle: (id) {
                            final updated = cityPrefs.preferredCityIds.toList();
                            updated.contains(id) ? updated.remove(id) : updated.add(id);
                            context.read<CityPreferencesProvider>().setPreferredCities(updated);
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
