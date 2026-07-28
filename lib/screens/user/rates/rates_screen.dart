import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/city_model.dart';
import '../../../models/rate_model.dart';
import '../../../providers/cities_provider.dart';
import '../../../providers/city_preferences_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/shimmer_list.dart';
import '../settings/city_selection_screen.dart';
import '../settings/user_settings_screen.dart';

/// Category tabs shown in this order regardless of [RateCategory]'s
/// declaration order (chicken, meat, egg) — chicken/eggs/meat reads better.
const _tabCategories = [RateCategory.chicken, RateCategory.egg, RateCategory.meat];

enum RatesViewMode { myCities, allCities }

/// Today's and yesterday's rates, one tab per category. Search starts
/// collapsed to a single icon and expands into the app bar in place of the
/// title when tapped, rather than permanently occupying its own row. A
/// compact My Cities / All Cities toggle plus an edit shortcut sits below
/// the tabs — small on purpose, since it's secondary to the rates
/// themselves.
class RatesScreen extends StatefulWidget {
  const RatesScreen({super.key});

  @override
  State<RatesScreen> createState() => _RatesScreenState();
}

class _RatesScreenState extends State<RatesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  bool _searching = false;
  String _query = '';
  RatesViewMode _viewMode = RatesViewMode.myCities;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCategories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _searchController.clear();
        _query = '';
      }
    });
  }

  void _editCities() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CitySelectionScreen()),
      );

  @override
  Widget build(BuildContext context) {
    final preferredCityIds = context.watch<CityPreferencesProvider>().preferredCityIds;

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'rates.searchHint'.tr(),
                  border: InputBorder.none,
                ),
              )
            : Text('rates.title'.tr()),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            tooltip: 'rates.searchHint'.tr(),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'nav.settings'.tr(),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const UserSettingsScreen()),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(38),
          child: TabBar(
            controller: _tabController,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
            tabs: _tabCategories.map((c) => Tab(height: 34, text: c.labelKey.tr())).toList(),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 4),
            child: Row(
              children: [
                SegmentedButton<RatesViewMode>(
                  segments: [
                    ButtonSegment(
                      value: RatesViewMode.myCities,
                      label: Text('rates.myCitiesOption'.tr()),
                    ),
                    ButtonSegment(
                      value: RatesViewMode.allCities,
                      label: Text('rates.allCitiesOption'.tr()),
                    ),
                  ],
                  selected: {_viewMode},
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onSelectionChanged: (selection) => setState(() => _viewMode = selection.first),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_location_alt_outlined, size: 20),
                  tooltip: 'rates.editMyCities'.tr(),
                  visualDensity: VisualDensity.compact,
                  onPressed: _editCities,
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabCategories
                  .map((category) => _CategoryRatesView(
                        category: category,
                        viewMode: _viewMode,
                        preferredCityIds: preferredCityIds,
                        searchQuery: _query,
                        onChangeCities: _editCities,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// One category's live "today" and "yesterday" rates, for either the
/// user's followed cities or every active city depending on [viewMode].
class _CategoryRatesView extends StatefulWidget {
  final RateCategory category;
  final RatesViewMode viewMode;
  final List<String> preferredCityIds;
  final String searchQuery;
  final VoidCallback onChangeCities;

  const _CategoryRatesView({
    required this.category,
    required this.viewMode,
    required this.preferredCityIds,
    required this.searchQuery,
    required this.onChangeCities,
  });

  @override
  State<_CategoryRatesView> createState() => _CategoryRatesViewState();
}

class _CategoryRatesViewState extends State<_CategoryRatesView>
    with AutomaticKeepAliveClientMixin<_CategoryRatesView> {
  StreamSubscription<List<RateModel>>? _sub;
  List<RateModel>? _recent;
  Object? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _subscribe() {
    _sub?.cancel();
    final firestore = context.read<FirestoreService>();
    _sub = firestore.watchRecentRateHistory(category: widget.category, days: 2).listen(
      (data) {
        if (!mounted) return;
        setState(() {
          _recent = data;
          _error = null;
        });
      },
      onError: (e) {
        debugPrint('watchRecentRateHistory (${widget.category}) error: $e');
        if (!mounted) return;
        setState(() => _error = e);
      },
    );
  }

  /// Latest entry per city among [all] that falls on [day] — [all] is
  /// already newest-first, so the first match per city is that day's most
  /// recent update.
  Map<String, RateModel> _ratesForDay(List<RateModel> all, DateTime day) {
    final map = <String, RateModel>{};
    for (final rate in all) {
      if (_dateOnly(rate.date) != day) continue;
      map.putIfAbsent(rate.cityId, () => rate);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.viewMode == RatesViewMode.myCities && widget.preferredCityIds.isEmpty) {
      return EmptyState(
        icon: Icons.star_outline_rounded,
        titleKey: 'rates.noFollowedCitiesTitle',
        subtitleKey: 'rates.noFollowedCitiesSubtitle',
        action: OutlinedButton(
          onPressed: widget.onChangeCities,
          child: Text('rates.changeCitiesOption'.tr()),
        ),
      );
    }

    if (_error != null) {
      return EmptyState(
        icon: Icons.error_outline,
        titleKey: 'common.errorLoadingTitle',
        subtitleKey: 'common.errorLoadingSubtitle',
        action: FilledButton(
          onPressed: _subscribe,
          child: Text('common.retry'.tr()),
        ),
      );
    }

    if (_recent == null) {
      return const ShimmerList();
    }

    final allCities = context.watch<CitiesProvider>().activeCities;
    var visibleCities = widget.viewMode == RatesViewMode.myCities
        ? allCities.where((c) => widget.preferredCityIds.contains(c.id)).toList()
        : List<CityModel>.from(allCities);
    final languageCode = context.locale.languageCode;
    visibleCities.sort((a, b) => a.localizedName(languageCode).compareTo(b.localizedName(languageCode)));

    final query = widget.searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      visibleCities = visibleCities
          .where((c) => c.localizedName(languageCode).toLowerCase().contains(query))
          .toList();
    }

    if (visibleCities.isEmpty) {
      return EmptyState(
        icon: query.isEmpty ? Icons.storefront_outlined : Icons.search_off,
        titleKey: query.isEmpty ? 'rates.emptyTitle' : 'dashboard.noSearchResultsTitle',
        subtitleKey: query.isEmpty ? 'rates.emptySubtitle' : 'dashboard.noSearchResultsSubtitle',
      );
    }

    final today = _dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    final todayRates = _ratesForDay(_recent!, today);
    final yesterdayRates = _ratesForDay(_recent!, yesterday);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        _DayRatesCard(
          label: AppFormatters.dayLabel(today, languageCode),
          dateLabel: AppFormatters.date(today, languageCode),
          category: widget.category,
          cities: visibleCities,
          ratesByCity: todayRates,
          previousRatesByCity: yesterdayRates,
          languageCode: languageCode,
          highlighted: true,
        ),
        const SizedBox(height: 14),
        _DayRatesCard(
          label: AppFormatters.dayLabel(yesterday, languageCode),
          dateLabel: AppFormatters.date(yesterday, languageCode),
          category: widget.category,
          cities: visibleCities,
          ratesByCity: yesterdayRates,
          previousRatesByCity: const {},
          languageCode: languageCode,
          highlighted: false,
        ),
      ],
    );
  }
}

/// One day's rates for every city currently in view, all in a single card.
/// A city with no entry for that day still gets a row — just with an empty
/// price — rather than being left out. [highlighted] gives the Today card a
/// filled category-colored badge and a tinted border so it reads as the
/// primary card at a glance, while Yesterday stays visually quieter.
class _DayRatesCard extends StatelessWidget {
  final String label;
  final String dateLabel;
  final RateCategory category;
  final List<CityModel> cities;
  final Map<String, RateModel> ratesByCity;
  final Map<String, RateModel> previousRatesByCity;
  final String languageCode;
  final bool highlighted;

  const _DayRatesCard({
    required this.label,
    required this.dateLabel,
    required this.category,
    required this.cities,
    required this.ratesByCity,
    required this.previousRatesByCity,
    required this.languageCode,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: highlighted ? category.color.withValues(alpha: 0.35) : theme.dividerColor,
          width: highlighted ? 1.4 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: highlighted ? category.color : category.color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    category.icon,
                    size: 16,
                    color: highlighted ? Colors.white : category.color,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  dateLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final city in cities)
              _CityRateRow(
                city: city,
                rate: ratesByCity[city.id],
                previousRate: previousRatesByCity[city.id],
                languageCode: languageCode,
                accentColor: category.color,
                showDivider: city != cities.last,
              ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _CityRateRow extends StatelessWidget {
  final CityModel city;
  final RateModel? rate;
  final RateModel? previousRate;
  final String languageCode;
  final Color accentColor;
  final bool showDivider;

  const _CityRateRow({
    required this.city,
    required this.rate,
    required this.previousRate,
    required this.languageCode,
    required this.accentColor,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasRate = rate != null;

    IconData? trendIcon;
    Color? trendColor;
    if (rate != null && previousRate != null && rate!.price != previousRate!.price) {
      final up = rate!.price > previousRate!.price;
      trendIcon = up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
      // Pricier is bad news for shoppers, cheaper is good — red/green reads
      // instantly without needing to parse the number.
      trendColor = up ? AppColors.error : AppColors.success;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasRate ? accentColor : theme.colorScheme.onSurface.withValues(alpha: 0.15),
                ),
              ),
              Expanded(
                child: Text(
                  city.localizedName(languageCode),
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasRate) ...[
                if (trendIcon != null) ...[
                  Icon(trendIcon, size: 14, color: trendColor),
                  const SizedBox(width: 2),
                ],
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rs. ${AppFormatters.price(rate!.price)}',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '/ ${rate!.unit}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ] else
                Text(
                  'rates.notSetYet'.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.6)),
      ],
    );
  }
}
