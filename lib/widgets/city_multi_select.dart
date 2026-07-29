import 'package:flutter/material.dart';
import '../models/city_model.dart';

/// A wrap of toggleable chips for picking multiple cities. Shared between
/// the first-launch onboarding screen and the dedicated CitySelectionScreen
/// (reached from Settings > My Cities and the Rates tab's empty state) so
/// they stay visually and behaviorally identical.
class CityMultiSelect extends StatelessWidget {
  final List<CityModel> cities;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;
  final String languageCode;

  const CityMultiSelect({
    super.key,
    required this.cities,
    required this.selectedIds,
    required this.onToggle,
    required this.languageCode,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: cities.map((city) {
        final selected = selectedIds.contains(city.id);
        return FilterChip(
          label: Text(city.localizedName(languageCode)),
          selected: selected,
          onSelected: (_) => onToggle(city.id),
          avatar: selected ? const Icon(Icons.check, size: 18) : null,
        );
      }).toList(),
    );
  }
}
