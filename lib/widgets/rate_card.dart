import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/formatters.dart';
import '../models/rate_model.dart';

/// The primary "price tile" used across the app: a category-colored icon,
/// city name, unit, and price — with an optional trend arrow when a
/// previous price is supplied, plus optional edit/delete actions for admin
/// screens.
class RateCard extends StatelessWidget {
  final RateModel rate;
  final double? previousPrice;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const RateCard({
    super.key,
    required this.rate,
    this.previousPrice,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final languageCode = context.locale.languageCode;
    final categoryColor = rate.category.color;
    final trend = previousPrice == null ? 0.0 : rate.price - previousPrice!;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(rate.category.icon, color: categoryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rate.cityName(languageCode),
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppFormatters.timeAgo(rate.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Rs. ${AppFormatters.price(rate.price)}',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        rate.unit,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                      if (trend != 0) ...[
                        const SizedBox(width: 6),
                        Icon(
                          trend > 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                          color: trend > 0 ? Colors.red : Colors.green,
                          size: 18,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              if (onEdit != null || onDelete != null)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'edit') onEdit?.call();
                    if (value == 'delete') onDelete?.call();
                  },
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      PopupMenuItem(value: 'edit', child: Text('common.edit'.tr())),
                    if (onDelete != null)
                      PopupMenuItem(value: 'delete', child: Text('common.delete'.tr())),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
