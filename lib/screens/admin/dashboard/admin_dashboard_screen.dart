import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/city_model.dart';
import '../../../models/rate_model.dart';
import '../../../providers/cities_provider.dart';
import '../../../providers/rates_provider.dart';
import '../../../widgets/empty_state.dart';
import '../rates/rate_form_sheet.dart';

/// Quick "today's rates at a glance, per city" overview with a fast path to
/// update any category for any city — item 2 of the admin spec ("update
/// daily poultry rates on the basis of different cities").
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cities = context.watch<CitiesProvider>().activeCities;
    final ratesProvider = context.watch<RatesProvider>();

    if (cities.isEmpty) {
      return const EmptyState(
        icon: Icons.location_city_outlined,
        titleKey: 'dashboard.noCitiesTitle',
        subtitleKey: 'dashboard.noCitiesSubtitle',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: cities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final city = cities[index];
        return _CityRatesCard(city: city, ratesProvider: ratesProvider);
      },
    );
  }
}

class _CityRatesCard extends StatelessWidget {
  final CityModel city;
  final RatesProvider ratesProvider;

  const _CityRatesCard({required this.city, required this.ratesProvider});

  RateModel? _latestFor(RateCategory category) {
    final list = ratesProvider.ratesFor(category);
    for (final rate in list) {
      if (rate.cityId == city.id) return rate;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final languageCode = context.locale.languageCode;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_city, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  city.localizedName(languageCode),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final category in RateCategory.values)
              _QuickRateRow(city: city, category: category, rate: _latestFor(category)),
          ],
        ),
      ),
    );
  }
}

class _QuickRateRow extends StatelessWidget {
  final CityModel city;
  final RateCategory category;
  final RateModel? rate;

  const _QuickRateRow({required this.city, required this.category, required this.rate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => showRateFormSheet(context, category: category, initialCityId: city.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(category.icon, size: 16, color: category.color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(category.labelKey.tr(), style: theme.textTheme.bodyMedium),
            ),
            if (rate != null) ...[
              Text(
                'Rs. ${AppFormatters.price(rate!.price)}',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 4),
              Text(
                '/ ${rate!.unit}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ] else
              Text(
                'dashboard.noRateYet'.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}
