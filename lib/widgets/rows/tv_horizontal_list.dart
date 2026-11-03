import 'package:flutter/material.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';

class TvHorizontalList extends StatelessWidget {
  const TvHorizontalList({
    super.key,
    required this.title,
    required this.itemCount,
    required this.itemBuilder,
  });

  final String title;
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  static const Color _accent = Color(0xFF36C8D5);

  @override
  Widget build(BuildContext context) {
    if (itemCount <= 0) return const SizedBox.shrink();

    final posterHeight = AppDimensions.posterHeight(context);
    final rowHeight =
        AppDimensions.movieCardHeight(context) +
        (posterHeight * (AppDimensions.focusScale - 1)) +
        28;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.sectionSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenHorizontal,
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 25,
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.sectionTitle.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _accent.withValues(alpha: 0.20)),
                  ),
                  child: Text(
                    '$itemCount',
                    style: const TextStyle(
                      color: _accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: rowHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenHorizontal,
                vertical: 12,
              ),
              itemCount: itemCount,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppDimensions.itemSpacing),
              itemBuilder: itemBuilder,
            ),
          ),
        ],
      ),
    );
  }
}
