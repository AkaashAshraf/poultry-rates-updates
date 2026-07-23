import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';

class UserSettingsScreen extends StatelessWidget {
  const UserSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: Text('settings.title'.tr())),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _SectionLabel(label: 'settings.language'.tr()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _LanguageOption(
                    label: 'English',
                    selected: context.locale.languageCode == 'en',
                    onTap: () => context.setLocale(const Locale('en')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LanguageOption(
                    label: 'اردو',
                    selected: context.locale.languageCode == 'ur',
                    onTap: () => context.setLocale(const Locale('ur')),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionLabel(label: 'settings.appearance'.tr()),
          // RadioListTile's own groupValue/onChanged were deprecated in
          // favor of an ancestor RadioGroup, which now owns the selection
          // state for every Radio/RadioListTile beneath it.
          RadioGroup<ThemeMode>(
            groupValue: themeProvider.mode,
            onChanged: (mode) => themeProvider.setMode(mode!),
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  title: Text('settings.systemDefault'.tr()),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  title: Text('settings.light'.tr()),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  title: Text('settings.dark'.tr()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionLabel(label: 'settings.administration'.tr()),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.primary),
            ),
            title: Text('settings.loginAsAdmin'.tr()),
            subtitle: Text('settings.loginAsAdminSubtitle'.tr()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              if (auth.isAdmin) {
                context.push(AppRoutes.adminHome);
              } else {
                context.push(AppRoutes.adminLogin);
              }
            },
          ),
          const SizedBox(height: 12),
          _SectionLabel(label: 'settings.about'.tr()),
          const _AppVersionTile(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary.withValues(alpha: 0.12) : null,
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.dividerColor,
            width: selected ? 1.6 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? theme.colorScheme.primary : null,
          ),
        ),
      ),
    );
  }
}

class _AppVersionTile extends StatelessWidget {
  const _AppVersionTile();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '1.0.0';
        return ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text('settings.appVersion'.tr()),
          trailing: Text(version),
        );
      },
    );
  }
}
