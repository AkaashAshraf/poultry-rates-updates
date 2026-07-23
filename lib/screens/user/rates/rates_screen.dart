import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../models/city_model.dart';
import '../../../models/rate_model.dart';
import '../../../providers/cities_provider.dart';
import '../../../providers/rates_provider.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/rate_card.dart';
import '../../../widgets/shimmer_list.dart';

class RatesScreen extends StatefulWidget {
  const RatesScreen({super.key});

  @override
  State<RatesScreen> createState() => _RatesScreenState();
}

class _RatesScreenState extends State<RatesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String? _selectedCityId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: RateCategory.values.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cities = context.watch<CitiesProvider>().activeCities;

    return Scaffold(
      appBar: AppBar(
        title: Text('rates.title'.tr()),
        bottom: TabBar(
          controller: _tabController,
          tabs: RateCategory.values
              .map((c) => Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(c.icon, size: 18, color: c.color),
                        const SizedBox(width: 6),
                        Text(c.labelKey.tr()),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _CityFilterChips(
              cities: cities,
              selectedCityId: _selectedCityId,
              onSelected: (id) => setState(() => _selectedCityId = id),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: RateCategory.values
                  .map((category) => _CategoryRatesList(
                        category: category,
                        cityFilter: _selectedCityId,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CityFilterChips extends StatelessWidget {
  final List<CityModel> cities;
  final String? selectedCityId;
  final ValueChanged<String?> onSelected;

  const _CityFilterChips({
    required this.cities,
    required this.selectedCityId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final languageCode = context.locale.languageCode;
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('common.allCities'.tr()),
              selected: selectedCityId == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final city in cities)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(city.localizedName(languageCode)),
                selected: selectedCityId == city.id,
                onSelected: (_) => onSelected(city.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryRatesList extends StatelessWidget {
  final RateCategory category;
  final String? cityFilter;

  const _CategoryRatesList({required this.category, required this.cityFilter});

  @override
  Widget build(BuildContext context) {
    final ratesProvider = context.watch<RatesProvider>();
    final isLoading = ratesProvider.loading[category] ?? true;

    if (isLoading) {
      return const ShimmerList();
    }

    List<RateModel> rates = ratesProvider.ratesFor(category);
    if (cityFilter != null) {
      rates = rates.where((r) => r.cityId == cityFilter).toList();
    }

    if (rates.isEmpty) {
      return EmptyState(
        icon: category.icon,
        titleKey: 'rates.emptyTitle',
        subtitleKey: 'rates.emptySubtitle',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rates.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => RateCard(rate: rates[index]),
    );
  }
}
