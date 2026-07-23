import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A row of shimmering placeholder cards, shown while Firestore streams
/// deliver their first snapshot.
class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double height;

  const ShimmerList({super.key, this.itemCount = 4, this.height = 88});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlight = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: base,
          highlightColor: highlight,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }
}
