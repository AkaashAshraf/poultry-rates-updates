import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/app_onboarding_content_model.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/primary_button.dart';

/// Admin screen for editing the first-launch welcome message and the
/// city-selection description shown during onboarding — see
/// WelcomeScreen and CityOnboardingScreen, which read this same
/// Firestore doc (`appConfig/onboarding`). Reached from the admin shell's
/// AppBar, not a bottom nav tab, since it's an occasional-use settings
/// screen rather than day-to-day content.
class AppContentScreen extends StatefulWidget {
  const AppContentScreen({super.key});

  @override
  State<AppContentScreen> createState() => _AppContentScreenState();
}

class _AppContentScreenState extends State<AppContentScreen> {
  late final Future<AppOnboardingContent> _contentFuture;

  @override
  void initState() {
    super.initState();
    _contentFuture = context.read<FirestoreService>().fetchOnboardingContent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('appContent.title'.tr())),
      body: FutureBuilder<AppOnboardingContent>(
        future: _contentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return _AppContentForm(initial: snapshot.data ?? const AppOnboardingContent());
        },
      ),
    );
  }
}

class _AppContentForm extends StatefulWidget {
  final AppOnboardingContent initial;
  const _AppContentForm({required this.initial});

  @override
  State<_AppContentForm> createState() => _AppContentFormState();
}

class _AppContentFormState extends State<_AppContentForm> {
  late final TextEditingController _welcomeTitleEn;
  late final TextEditingController _welcomeTitleUr;
  late final TextEditingController _welcomeMessageEn;
  late final TextEditingController _welcomeMessageUr;
  late final TextEditingController _cityDescriptionEn;
  late final TextEditingController _cityDescriptionUr;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _welcomeTitleEn = TextEditingController(text: widget.initial.welcomeTitleEn);
    _welcomeTitleUr = TextEditingController(text: widget.initial.welcomeTitleUr);
    _welcomeMessageEn = TextEditingController(text: widget.initial.welcomeMessageEn);
    _welcomeMessageUr = TextEditingController(text: widget.initial.welcomeMessageUr);
    _cityDescriptionEn = TextEditingController(text: widget.initial.citySelectionDescriptionEn);
    _cityDescriptionUr = TextEditingController(text: widget.initial.citySelectionDescriptionUr);
  }

  @override
  void dispose() {
    _welcomeTitleEn.dispose();
    _welcomeTitleUr.dispose();
    _welcomeMessageEn.dispose();
    _welcomeMessageUr.dispose();
    _cityDescriptionEn.dispose();
    _cityDescriptionUr.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final content = AppOnboardingContent(
      welcomeTitleEn: _welcomeTitleEn.text.trim(),
      welcomeTitleUr: _welcomeTitleUr.text.trim(),
      welcomeMessageEn: _welcomeMessageEn.text.trim(),
      welcomeMessageUr: _welcomeMessageUr.text.trim(),
      citySelectionDescriptionEn: _cityDescriptionEn.text.trim(),
      citySelectionDescriptionUr: _cityDescriptionUr.text.trim(),
    );
    await context.read<FirestoreService>().updateOnboardingContent(content);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('appContent.saved'.tr())));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'appContent.welcomeSection'.tr(),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'appContent.welcomeSectionSubtitle'.tr(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _welcomeTitleEn,
            textDirection: ui.TextDirection.ltr,
            textAlign: TextAlign.left,
            decoration: InputDecoration(
              labelText: 'appContent.welcomeTitleEnglish'.tr(),
              hintText: 'welcome.title'.tr(),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _welcomeTitleUr,
            textDirection: ui.TextDirection.rtl,
            textAlign: TextAlign.right,
            decoration: InputDecoration(labelText: 'appContent.welcomeTitleUrdu'.tr()),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _welcomeMessageEn,
            textDirection: ui.TextDirection.ltr,
            textAlign: TextAlign.left,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'appContent.welcomeMessageEnglish'.tr(),
              hintText: 'welcome.subtitle'.tr(),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _welcomeMessageUr,
            textDirection: ui.TextDirection.rtl,
            textAlign: TextAlign.right,
            maxLines: 4,
            decoration: InputDecoration(labelText: 'appContent.welcomeMessageUrdu'.tr()),
          ),
          const SizedBox(height: 28),
          Text(
            'appContent.citySection'.tr(),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'appContent.citySectionSubtitle'.tr(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cityDescriptionEn,
            textDirection: ui.TextDirection.ltr,
            textAlign: TextAlign.left,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'appContent.cityDescriptionEnglish'.tr(),
              hintText: 'onboarding.subtitle'.tr(),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _cityDescriptionUr,
            textDirection: ui.TextDirection.rtl,
            textAlign: TextAlign.right,
            maxLines: 3,
            decoration: InputDecoration(labelText: 'appContent.cityDescriptionUrdu'.tr()),
          ),
          const SizedBox(height: 24),
          PrimaryButton(label: 'common.save'.tr(), isLoading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}
