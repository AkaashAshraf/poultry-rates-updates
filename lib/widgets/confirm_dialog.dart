import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String titleKey,
  required String messageKey,
  String confirmKey = 'common.delete',
  bool danger = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titleKey.tr()),
      content: Text(messageKey.tr()),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('common.cancel'.tr()),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: danger ? AppColors.error : null),
          child: Text(confirmKey.tr()),
        ),
      ],
    ),
  );
  return result ?? false;
}
