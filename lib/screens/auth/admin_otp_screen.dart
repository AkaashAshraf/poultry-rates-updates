import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/primary_button.dart';

class AdminOtpScreen extends StatefulWidget {
  const AdminOtpScreen({super.key});

  @override
  State<AdminOtpScreen> createState() => _AdminOtpScreenState();
}

class _AdminOtpScreenState extends State<AdminOtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(AppConstants.otpLength, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(AppConstants.otpLength, (_) => FocusNode());

  int _secondsLeft = AppConstants.otpResendSeconds;
  Timer? _timer;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsLeft = AppConstants.otpResendSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft <= 0) {
        timer.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _clearCode() {
    for (final c in _controllers) {
      c.clear();
    }
    _nodes.first.requestFocus();
  }

  /// Spreads a multi-digit string (from SMS autofill or a manual paste)
  /// across the OTP boxes starting at [startIndex], filling forward and
  /// clearing anything left over in later boxes.
  void _distributeCode(String digits, int startIndex) {
    var remaining = digits;
    var i = startIndex;
    while (i < AppConstants.otpLength && remaining.isNotEmpty) {
      _controllers[i].text = remaining.substring(0, 1);
      _controllers[i].selection = const TextSelection.collapsed(offset: 1);
      remaining = remaining.substring(1);
      i++;
    }
    for (var j = i; j < AppConstants.otpLength; j++) {
      _controllers[j].clear();
    }

    final nextFocus = i < AppConstants.otpLength ? i : AppConstants.otpLength - 1;
    _nodes[nextFocus].requestFocus();
    if (_code.length == AppConstants.otpLength) {
      FocusScope.of(context).unfocus();
    }
    setState(() {});
  }

  Future<void> _verify() async {
    if (_code.length != AppConstants.otpLength) {
      setState(() => _error = 'auth.enterFullCode');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();

    // A previous failed attempt (wrong code, expired session, or
    // not-authorized) invalidates the verification session — the provider
    // clears it in that case. Rather than silently no-op, send the user
    // straight to requesting a fresh code.
    if (auth.pendingVerificationExpired) {
      setState(() {
        _submitting = false;
        _error = 'auth.codeExpiredResend';
      });
      _clearCode();
      return;
    }

    final success = await auth.confirmOtp(_code);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      context.go(AppRoutes.adminHome);
    } else {
      setState(() => _error = auth.errorMessage ?? 'auth.invalidCode');
      _clearCode();
    }
  }

  Future<void> _resend() async {
    final auth = context.read<AuthProvider>();
    if (auth.pendingPhoneNumber == null) return;
    await auth.sendOtp(auth.pendingPhoneNumber!);
    if (!mounted) return;
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'auth.verifyTitle'.tr(),
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'auth.verifySubtitle'.tr(args: [auth.pendingPhoneNumber ?? '']),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(AppConstants.otpLength, (index) {
                  return SizedBox(
                    width: 46,
                    height: 56,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _nodes[index],
                      textAlign: TextAlign.center,
                      textAlignVertical: TextAlignVertical.center,
                      keyboardType: TextInputType.number,
                      // No maxLength here on purpose: Android's SMS-code
                      // autofill/paste drops the whole 6-digit code into a
                      // single box. Capping length to 1 truncates that
                      // paste before we ever see it, so we accept the full
                      // string and redistribute it across the boxes below.
                      style: theme.textTheme.titleLarge,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        counterText: '',
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onTap: () {
                        // Select any existing digit so typing overwrites it
                        // instead of appending and overflowing the box.
                        _controllers[index].selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: _controllers[index].text.length,
                        );
                      },
                      onChanged: (value) {
                        final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

                        if (digits.length > 1) {
                          _distributeCode(digits, index);
                          return;
                        }

                        if (_controllers[index].text != digits) {
                          _controllers[index].text = digits;
                          _controllers[index].selection =
                              TextSelection.collapsed(offset: digits.length);
                        }

                        if (digits.isNotEmpty && index < AppConstants.otpLength - 1) {
                          _nodes[index + 1].requestFocus();
                        } else if (digits.isEmpty && index > 0) {
                          _nodes[index - 1].requestFocus();
                        }
                        if (_code.length == AppConstants.otpLength) {
                          FocusScope.of(context).unfocus();
                        }
                        setState(() {});
                      },
                    ),
                  );
                }),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!.tr(), style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ],
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'auth.verify'.tr(),
                isLoading: _submitting,
                onPressed: _verify,
              ),
              const SizedBox(height: 20),
              Center(
                child: _secondsLeft > 0
                    ? Text(
                        'auth.resendIn'.tr(args: ['$_secondsLeft']),
                        style: theme.textTheme.bodySmall,
                      )
                    : TextButton(onPressed: _resend, child: Text('auth.resendCode'.tr())),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
