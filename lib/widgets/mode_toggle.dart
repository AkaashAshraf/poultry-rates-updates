import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Segmented "Admin Mode / User Mode" switcher shown to authorized admins
/// so they can jump between the public app and the admin panel without
/// logging out. [isAdminMode] reflects which side is currently active; the
/// active segment is disabled (tapping it is a no-op) and the inactive one
/// invokes the matching callback to navigate.
class ModeToggle extends StatelessWidget {
  final bool isAdminMode;
  final VoidCallback onAdminMode;
  final VoidCallback onUserMode;

  const ModeToggle({
    super.key,
    required this.isAdminMode,
    required this.onAdminMode,
    required this.onUserMode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeSegment(
              icon: Icons.admin_panel_settings_rounded,
              label: 'modeToggle.adminMode'.tr(),
              selected: isAdminMode,
              onTap: onAdminMode,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _ModeSegment(
              icon: Icons.storefront_rounded,
              label: 'modeToggle.userMode'.tr(),
              selected: !isAdminMode,
              onTap: onUserMode,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSegment extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeSegment({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: selected ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: selected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.65),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
