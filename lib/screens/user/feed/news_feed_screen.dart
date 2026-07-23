import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/news_model.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/shimmer_list.dart';

class NewsFeedScreen extends StatelessWidget {
  const NewsFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final languageCode = context.locale.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text('feed.title'.tr()),
      ),
      body: StreamBuilder<List<NewsModel>>(
        stream: firestore.watchNews(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const ShimmerList(itemCount: 5, height: 140);
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
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) => _NewsCard(news: items[index], languageCode: languageCode),
          );
        },
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsModel news;
  final String languageCode;

  const _NewsCard({required this.news, required this.languageCode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (news.imageUrl != null && news.imageUrl!.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: news.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: AppColors.primary.withValues(alpha: 0.06)),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  news.title(languageCode),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  news.body(languageCode),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Text(
                  AppFormatters.dateTime(news.createdAt, languageCode),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
