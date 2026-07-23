import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../models/app_user_model.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/shimmer_list.dart';

/// Read-only visibility into app users — item 4 of the admin spec. Regular
/// users never log in, so this list reflects anonymous sessions plus any
/// admin accounts, letting the app owner see rough usage at a glance.
class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final languageCode = context.locale.languageCode;

    return StreamBuilder<List<AppUserModel>>(
      stream: firestore.watchUsers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ShimmerList(itemCount: 6, height: 72);
        }
        final users = snapshot.data!;
        if (users.isEmpty) {
          return const EmptyState(
            icon: Icons.people_outline,
            titleKey: 'users.emptyTitle',
            subtitleKey: 'users.emptySubtitle',
          );
        }

        return Column(
          children: [
            _UsersSummaryBar(count: users.length, admins: users.where((u) => u.isAdmin).length),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: users.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _UserTile(user: users[index], languageCode: languageCode),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UsersSummaryBar extends StatelessWidget {
  final int count;
  final int admins;
  const _UsersSummaryBar({required this.count, required this.admins});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _StatItem(label: 'users.totalUsers'.tr(), value: '$count'),
          Container(width: 1, height: 30, color: theme.dividerColor),
          const SizedBox(width: 16),
          _StatItem(label: 'users.totalAdmins'.tr(), value: '$admins'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final AppUserModel user;
  final String languageCode;
  const _UserTile({required this.user, required this.languageCode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.isAdmin
              ? theme.colorScheme.primary.withValues(alpha: 0.14)
              : theme.colorScheme.onSurface.withValues(alpha: 0.06),
          child: Icon(
            user.isAdmin ? Icons.admin_panel_settings : Icons.person_outline,
            color: user.isAdmin ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            size: 20,
          ),
        ),
        title: Text(
          user.isAdmin ? (user.phoneNumber ?? 'users.admin'.tr()) : 'users.guestUser'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          user.lastSeenAt != null
              ? 'users.lastActive'.tr(args: [AppFormatters.dateTime(user.lastSeenAt!, languageCode)])
              : '—',
        ),
        trailing: user.isAdmin
            ? Chip(
                label: Text('users.admin'.tr()),
                visualDensity: VisualDensity.compact,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                labelStyle: TextStyle(color: theme.colorScheme.primary, fontSize: 12),
              )
            : null,
      ),
    );
  }
}
