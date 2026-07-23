import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/city_model.dart';
import '../../../providers/cities_provider.dart';
import '../../../widgets/primary_button.dart';

Future<void> showCityFormSheet(BuildContext context, {CityModel? existing}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _CityFormSheet(existing: existing),
  );
}

class _CityFormSheet extends StatefulWidget {
  final CityModel? existing;
  const _CityFormSheet({this.existing});

  @override
  State<_CityFormSheet> createState() => _CityFormSheetState();
}

class _CityFormSheetState extends State<_CityFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameEnController;
  late final TextEditingController _nameUrController;
  bool _isActive = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameEnController = TextEditingController(text: widget.existing?.nameEn ?? '');
    _nameUrController = TextEditingController(text: widget.existing?.nameUr ?? '');
    _isActive = widget.existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameUrController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final citiesProvider = context.read<CitiesProvider>();
    if (widget.existing == null) {
      await citiesProvider.addCity(_nameEnController.text.trim(), _nameUrController.text.trim());
    } else {
      await citiesProvider.updateCity(
        widget.existing!.copyWith(
          nameEn: _nameEnController.text.trim(),
          nameUr: _nameUrController.text.trim(),
          isActive: _isActive,
        ),
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
            Text(
              (isEditing ? 'cities.editTitle' : 'cities.addTitle').tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            // Both name fields are pinned to a fixed text direction
            // regardless of the app's current language — an English city
            // name should always type left-to-right, and an Urdu one
            // right-to-left, even when the surrounding UI is mirrored for
            // Urdu (where ambient Directionality is RTL) or vice versa.
            TextFormField(
              controller: _nameEnController,
              textDirection: ui.TextDirection.ltr,
              textAlign: TextAlign.left,
              decoration: InputDecoration(labelText: 'cities.nameEnglish'.tr()),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'validation.required'.tr() : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _nameUrController,
              textDirection: ui.TextDirection.rtl,
              textAlign: TextAlign.right,
              decoration: InputDecoration(labelText: 'cities.nameUrdu'.tr()),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'validation.required'.tr() : null,
            ),
            if (isEditing) ...[
              const SizedBox(height: 6),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isActive,
                title: Text('cities.active'.tr()),
                onChanged: (value) => setState(() => _isActive = value),
              ),
            ],
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
