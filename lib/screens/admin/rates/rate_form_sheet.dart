import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../models/city_model.dart';
import '../../../models/rate_model.dart';
import '../../../providers/cities_provider.dart';
import '../../../providers/rates_provider.dart';
import '../../../widgets/primary_button.dart';

Future<void> showRateFormSheet(
  BuildContext context, {
  required RateCategory category,
  RateModel? existing,
  String? initialCityId,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _RateFormSheet(category: category, existing: existing, initialCityId: initialCityId),
  );
}

class _RateFormSheet extends StatefulWidget {
  final RateCategory category;
  final RateModel? existing;
  final String? initialCityId;
  const _RateFormSheet({required this.category, this.existing, this.initialCityId});

  @override
  State<_RateFormSheet> createState() => _RateFormSheetState();
}

class _RateFormSheetState extends State<_RateFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _priceController;
  late final TextEditingController _unitController;
  String? _cityId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.existing != null ? widget.existing!.price.toString() : '',
    );
    _unitController = TextEditingController(
      text: widget.existing?.unit ?? widget.category.defaultUnitKey.tr(),
    );
    _cityId = widget.existing?.cityId ?? widget.initialCityId;
  }

  @override
  void dispose() {
    _priceController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cityId == null) return;

    setState(() => _saving = true);

    final cities = context.read<CitiesProvider>().cities;
    final city = cities.firstWhere((c) => c.id == _cityId);
    final ratesProvider = context.read<RatesProvider>();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final price = double.tryParse(_priceController.text.trim()) ?? 0;

    final rate = RateModel(
      id: widget.existing?.id ?? '',
      category: widget.category,
      cityId: city.id,
      cityNameEn: city.nameEn,
      cityNameUr: city.nameUr,
      price: price,
      unit: _unitController.text.trim(),
      date: DateTime.now(),
      updatedByUid: uid,
    );

    if (widget.existing == null) {
      await ratesProvider.addRate(rate);
    } else {
      await ratesProvider.updateRate(rate);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cities = context.watch<CitiesProvider>().activeCities;
    final isEditing = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(widget.category.icon, color: widget.category.color),
                const SizedBox(width: 8),
                Text(
                  '${(isEditing ? 'rates.updateTitle' : 'rates.addTitle').tr()} — ${widget.category.labelKey.tr()}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: cities.any((c) => c.id == _cityId) ? _cityId : null,
              decoration: InputDecoration(labelText: 'common.city'.tr()),
              items: cities
                  .map((CityModel c) => DropdownMenuItem(value: c.id, child: Text(c.nameEn)))
                  .toList(),
              onChanged: (value) => setState(() => _cityId = value),
              validator: (value) => value == null ? 'validation.required'.tr() : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'rates.price'.tr(), prefixText: 'Rs. '),
              validator: (value) {
                final parsed = double.tryParse(value?.trim() ?? '');
                if (parsed == null || parsed <= 0) return 'validation.enterValidPrice'.tr();
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _unitController,
              decoration: InputDecoration(labelText: 'rates.unit'.tr()),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'validation.required'.tr() : null,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'common.save'.tr(),
              isLoading: _saving,
              onPressed: _save,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
