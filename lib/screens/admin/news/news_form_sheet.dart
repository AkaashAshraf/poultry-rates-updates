import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/news_model.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/primary_button.dart';

Future<void> showNewsFormSheet(BuildContext context, {NewsModel? existing}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _NewsFormSheet(existing: existing),
  );
}

class _NewsFormSheet extends StatefulWidget {
  final NewsModel? existing;
  const _NewsFormSheet({this.existing});

  @override
  State<_NewsFormSheet> createState() => _NewsFormSheetState();
}

class _NewsFormSheetState extends State<_NewsFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleEnController;
  late final TextEditingController _titleUrController;
  late final TextEditingController _bodyEnController;
  late final TextEditingController _bodyUrController;
  late final TextEditingController _imageUrlController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleEnController = TextEditingController(text: widget.existing?.titleEn ?? '');
    _titleUrController = TextEditingController(text: widget.existing?.titleUr ?? '');
    _bodyEnController = TextEditingController(text: widget.existing?.bodyEn ?? '');
    _bodyUrController = TextEditingController(text: widget.existing?.bodyUr ?? '');
    _imageUrlController = TextEditingController(text: widget.existing?.imageUrl ?? '');
  }

  @override
  void dispose() {
    _titleEnController.dispose();
    _titleUrController.dispose();
    _bodyEnController.dispose();
    _bodyUrController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final firestore = context.read<FirestoreService>();
    final news = NewsModel(
      id: widget.existing?.id ?? '',
      titleEn: _titleEnController.text.trim(),
      titleUr: _titleUrController.text.trim(),
      bodyEn: _bodyEnController.text.trim(),
      bodyUr: _bodyUrController.text.trim(),
      imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    if (widget.existing == null) {
      await firestore.addNews(news);
    } else {
      await firestore.updateNews(news);
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
      child: SingleChildScrollView(
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
                (isEditing ? 'feed.editTitle' : 'feed.addTitle').tr(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              // Title/body fields are pinned to a fixed text direction
              // regardless of the app's current language, same reasoning
              // as the city name fields in city_form_sheet.dart.
              TextFormField(
                controller: _titleEnController,
                textDirection: ui.TextDirection.ltr,
                textAlign: TextAlign.left,
                decoration: InputDecoration(labelText: 'feed.titleEnglish'.tr()),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'validation.required'.tr() : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _titleUrController,
                textDirection: ui.TextDirection.rtl,
                textAlign: TextAlign.right,
                decoration: InputDecoration(labelText: 'feed.titleUrdu'.tr()),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'validation.required'.tr() : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _bodyEnController,
                textDirection: ui.TextDirection.ltr,
                textAlign: TextAlign.left,
                maxLines: 4,
                decoration: InputDecoration(labelText: 'feed.bodyEnglish'.tr()),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'validation.required'.tr() : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _bodyUrController,
                textDirection: ui.TextDirection.rtl,
                textAlign: TextAlign.right,
                maxLines: 4,
                decoration: InputDecoration(labelText: 'feed.bodyUrdu'.tr()),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'validation.required'.tr() : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _imageUrlController,
                textDirection: ui.TextDirection.ltr,
                textAlign: TextAlign.left,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'feed.imageUrl'.tr(),
                  hintText: 'https://…',
                ),
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
      ),
    );
  }
}
