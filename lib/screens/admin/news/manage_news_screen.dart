import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../models/news_model.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/shimmer_list.dart';
import 'news_form_sheet.dart';

/// Admin CRUD for news/feed posts — the app-owner-facing counterpart to
/// the read-only NewsFeedScreen regular users see.
class ManageNewsScreen extends StatelessWidget {
  const ManageNewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final languageCode = context.locale.languageCode;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'manageNewsFab',
        onPressed: () => showNewsFormSheet(context),
        icon: const Icon(Icons.add),
        label: Text('feed.add'.tr()),
      ),
      body: StreamBuilder<List<NewsModel>>(
        stream: firestore.watchNews(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('watchNews error: ${snapshot.error}');
            return EmptyState(
              icon: Icons.error_outline,
              titleKey: 'common.errorLoadingTitle',
              subtitleKey: 'common.errorLoadingSubtitle',
            );
          }
          if (!snapshot.hasData) {
            return const ShimmerList(itemCount: 5, height: 96);
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.dynamic_feed_outlined,
              titleKey: 'feed.emptyTitle',
              subtitleKey: 'feed.emptySubtitle',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _NewsTile(news: items[index], languageCode: languageCode),
          );
        },
      ),
    );
  }
}

class _NewsTile extends StatelessWidget {
  final NewsModel news;
  final String languageCode;

  const _NewsTile({required this.news, required this.languageCode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(Icons.dynamic_feed, color: theme.colorScheme.primary, size: 20),
        ),
        title: Text(
          news.title(languageCode),
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          AppFormatters.dateTime(news.createdAt, languageCode),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => showNewsFormSheet(context, existing: news),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirmed = await showConfirmDialog(
                  context,
                  titleKey: 'feed.deleteTitle',
                  messageKey: 'feed.deleteMessage',
                );
                if (confirmed && context.mounted) {
                  await context.read<FirestoreService>().deleteNews(news.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
