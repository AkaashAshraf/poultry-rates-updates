import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../models/rate_model.dart';
import '../../../providers/cities_provider.dart';
import '../../../providers/rates_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/rate_card.dart';
import 'rate_form_sheet.dart';

/// Full CRUD for chicken / meat / egg rates — items 5, 6 and 7 of the
/// admin spec. Each category is its own tab; every entry can be edited or
/// deleted, and new entries can be added per city.
class ManageRatesScreen extends StatefulWidget {
  const ManageRatesScreen({super.key});

  @override
  State<ManageRatesScreen> createState() => _ManageRatesScreenState();
}

class _ManageRatesScreenState extends State<ManageRatesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

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

  RateCategory get _currentCategory => RateCategory.values[_tabController.index];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('rates.manageTitle'.tr()),
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showRateFormSheet(context, category: _currentCategory),
        icon: const Icon(Icons.add),
        label: Text('rates.add'.tr()),
      ),
      body: TabBarView(
        controller: _tabController,
        children: RateCategory.values.map((category) => _RateHistoryList(category: category)).toList(),
      ),
    );
  }
}

class _RateHistoryList extends StatefulWidget {
  final RateCategory category;
  const _RateHistoryList({required this.category});

  @override
  State<_RateHistoryList> createState() => _RateHistoryListState();
}

class _RateHistoryListState extends State<_RateHistoryList> {
  String? _cityFilter;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final cities = context.watch<CitiesProvider>().cities;
    final languageCode = context.locale.languageCode;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('common.allCities'.tr()),
                    selected: _cityFilter == null,
                    onSelected: (_) => setState(() => _cityFilter = null),
                  ),
                ),
                for (final city in cities)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(city.localizedName(languageCode)),
                      selected: _cityFilter == city.id,
                      onSelected: (_) => setState(() => _cityFilter = city.id),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<RateModel>>(
            stream: firestore.watchAllRatesForCategory(widget.category, cityId: _cityFilter),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final rates = snapshot.data!;
              if (rates.isEmpty) {
                return EmptyState(
                  icon: widget.category.icon,
                  titleKey: 'rates.emptyTitle',
                  subtitleKey: 'rates.emptySubtitle',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                itemCount: rates.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final rate = rates[index];
                  return RateCard(
                    rate: rate,
                    onEdit: () => showRateFormSheet(context, category: widget.category, existing: rate),
                    onDelete: () async {
                      final confirmed = await showConfirmDialog(
                        context,
                        titleKey: 'rates.deleteTitle',
                        messageKey: 'rates.deleteMessage',
                      );
                      if (confirmed && context.mounted) {
                        await context.read<RatesProvider>().deleteRate(rate.id);
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
