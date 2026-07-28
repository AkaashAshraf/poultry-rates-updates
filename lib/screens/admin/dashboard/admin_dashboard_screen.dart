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
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

    final query = _query.trim().toLowerCase();
    final matchingCities = query.isEmpty
        ? cities
        : cities
            .where((c) =>
                c.nameEn.toLowerCase().contains(query) || c.nameUr.toLowerCase().contains(query))
            .toList();

    // Cities still missing at least one category's rate for today float to
    // the top — that's the whole point of this screen: showing the admin
    // what still needs updating. Within each group, the existing
    // (alphabetical) order from CitiesProvider is preserved.
    final pending = matchingCities.where((c) => _isPendingToday(c, ratesProvider)).toList();
    final upToDate = matchingCities.where((c) => !_isPendingToday(c, ratesProvider)).toList();
    final filteredCities = [...pending, ...upToDate];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'dashboard.searchHint'.tr(),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: filteredCities.isEmpty
              ? EmptyState(
                  icon: Icons.search_off,
                  titleKey: 'dashboard.noSearchResultsTitle',
                  subtitleKey: 'dashboard.noSearchResultsSubtitle',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: filteredCities.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final city = filteredCities[index];
                    return _CityRatesCard(
                      city: city,
                      ratesProvider: ratesProvider,
                      pending: _isPendingToday(city, ratesProvider),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// True if any of the three categories hasn't had a rate entered for
/// [city] yet today — either no rate exists at all, or the latest one on
/// record is from an earlier day.
bool _isPendingToday(CityModel city, RatesProvider ratesProvider) {
  final today = DateTime.now();
  for (final category in RateCategory.values) {
    final rates = ratesProvider.ratesFor(category);
    RateModel? latest;
    for (final rate in rates) {
      if (rate.cityId == city.id) {
        latest = rate;
        break;
      }
    }
    if (latest == null || !_isSameDay(latest.date, today)) {
      return true;
    }
  }
  return false;
}

class _CityRatesCard extends StatelessWidget {
  final CityModel city;
  final RatesProvider ratesProvider;
  final bool pending;

  const _CityRatesCard({required this.city, required this.ratesProvider, required this.pending});

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
      shape: pending
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.tertiary.withValues(alpha: 0.5)),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_city, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    city.localizedName(languageCode),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (pending)
                  Chip(
                    label: Text('dashboard.pendingToday'.tr()),
                    labelStyle: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: theme.colorScheme.tertiaryContainer,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
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
    final updatedToday = rate != null && _isSameDay(rate!.date, DateTime.now());

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
              if (!updatedToday) ...[
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(color: theme.colorScheme.tertiary, shape: BoxShape.circle),
                ),
              ],
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
