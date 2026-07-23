import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';

import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/primary_button.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  String? _e164Phone;
  bool _submitting = false;
  String? _error;

  Future<void> _submit() async {
    if (_e164Phone == null || _e164Phone!.isEmpty) {
      setState(() => _error = 'auth.enterValidPhone');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    await auth.sendOtp(_e164Phone!);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (auth.status == AdminAuthStatus.codeSent) {
      context.push(AppRoutes.adminOtp);
    } else if (auth.errorMessage != null) {
      setState(() => _error = auth.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                'auth.adminLoginTitle'.tr(),
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'auth.adminLoginSubtitle'.tr(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 32),
              Text('auth.phoneNumber'.tr(), style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              IntlPhoneField(
                initialCountryCode: 'PK',
                disableLengthCheck: true,
                flagsButtonPadding: const EdgeInsets.only(left: 12),
                decoration: const InputDecoration(counterText: ''),
                dropdownTextStyle: theme.textTheme.bodyMedium,
                onChanged: (phone) {
                  _e164Phone = phone.completeNumber.startsWith('+')
                      ? phone.completeNumber
                      : '+${phone.completeNumber}';
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!.tr(),
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ],
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'auth.sendCode'.tr(),
                isLoading: _submitting,
                onPressed: _submit,
              ),
              const SizedBox(height: 16),
              Text(
                'auth.adminOnlyNotice'.tr(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
