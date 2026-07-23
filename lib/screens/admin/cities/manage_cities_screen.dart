import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/city_model.dart';
import '../../../providers/cities_provider.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/empty_state.dart';
import 'city_form_sheet.dart';

class ManageCitiesScreen extends StatelessWidget {
  const ManageCitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final citiesProvider = context.watch<CitiesProvider>();
    final languageCode = context.locale.languageCode;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCityFormSheet(context),
        icon: const Icon(Icons.add),
        label: Text('cities.add'.tr()),
      ),
      body: citiesProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : citiesProvider.cities.isEmpty
              ? const EmptyState(
                  icon: Icons.location_city_outlined,
                  titleKey: 'cities.emptyTitle',
                  subtitleKey: 'cities.emptySubtitle',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: citiesProvider.cities.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final city = citiesProvider.cities[index];
                    return _CityTile(city: city, languageCode: languageCode);
                  },
                ),
    );
  }
}

class _CityTile extends StatelessWidget {
  final CityModel city;
  final String languageCode;

  const _CityTile({required this.city, required this.languageCode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(Icons.location_city, color: theme.colorScheme.primary, size: 20),
        ),
        title: Text(city.nameEn, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(city.nameUr),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!city.isActive)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text('cities.inactive'.tr()),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => showCityFormSheet(context, existing: city),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirmed = await showConfirmDialog(
                  context,
                  titleKey: 'cities.deleteTitle',
                  messageKey: 'cities.deleteMessage',
                );
                if (confirmed && context.mounted) {
                  await context.read<CitiesProvider>().deleteCity(city.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
