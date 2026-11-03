
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../models/video_model.dart';
import '../cards/tv_movie_card_landscape.dart';

class TvMovieRowLandscape extends StatefulWidget {
  const TvMovieRowLandscape({
    super.key,
    required this.title,
    required this.videos,
    this.firstFocusNode,
    this.onVideoPressed,
    this.onViewAll,
    this.viewAllFocusNode,
    this.onNavigateUp,
    this.onNavigateDown,
    this.onFocusNodesChanged,
    this.onRegisterFocusRequest,
  });

  final String title;
  final List<VideoModel> videos;
  final FocusNode? firstFocusNode;
  final ValueChanged<VideoModel>? onVideoPressed;
  final VoidCallback? onViewAll;
  final FocusNode? viewAllFocusNode;
  final ValueChanged<int>? onNavigateUp;
  final ValueChanged<int>? onNavigateDown;
  final ValueChanged<List<FocusNode>>? onFocusNodesChanged;
  final ValueChanged<ValueChanged<int>>? onRegisterFocusRequest;

  @override
  State<TvMovieRowLandscape> createState() =>
      _TvMovieRowLandscapeState();
}

class _TvMovieRowLandscapeState extends State<TvMovieRowLandscape> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, FocusNode> _cardFocusNodes = {};

  int? _pendingFocusIndex;
  int _navigationGeneration = 0;

  List<VideoModel> get _visibleVideos =>
      widget.videos.take(10).toList(growable: false);

  double _cardWidth(BuildContext context) =>
      AppDimensions.posterWidth(context) * 1.65;

  double _cardHeight(BuildContext context) =>
      _cardWidth(context) * 9 / 16;

  @override
  void initState() {
    super.initState();
    _syncFocusNodes();
    _notifyFocusNodesChanged();
    _registerFocusRequest();
  }

  @override
  void didUpdateWidget(covariant TvMovieRowLandscape oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncFocusNodes();
    _notifyFocusNodesChanged();
    _registerFocusRequest();
  }

  void _registerFocusRequest() {
    widget.onRegisterFocusRequest?.call(
      (index) => _moveToIndex(index, animate: false),
    );
  }

  void _syncFocusNodes() {
    final count = _visibleVideos.length;

    for (final index in _cardFocusNodes.keys.toList()) {
      if (index >= count ||
          (index == 0 && widget.firstFocusNode != null)) {
        final node = _cardFocusNodes.remove(index);
        node?.dispose();
      }
    }

    for (var index = 0; index < count; index++) {
      if (index == 0 && widget.firstFocusNode != null) continue;

      _cardFocusNodes.putIfAbsent(
        index,
        () => FocusNode(
          debugLabel: '${widget.title}_LandscapeCard_$index',
        ),
      );
    }

    if (_pendingFocusIndex != null &&
        _pendingFocusIndex! >= count) {
      _pendingFocusIndex = count > 0 ? count - 1 : null;
    }
  }

  FocusNode _focusNodeFor(int index) {
    if (index == 0 && widget.firstFocusNode != null) {
      return widget.firstFocusNode!;
    }

    return _cardFocusNodes[index]!;
  }

  void _notifyFocusNodesChanged() {
    final nodes = List<FocusNode>.generate(
      _visibleVideos.length,
      _focusNodeFor,
      growable: false,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onFocusNodesChanged?.call(nodes);
      }
    });
  }

  KeyEventResult _handleCardKeyEvent(
    int index,
    FocusNode node,
    KeyEvent event,
  ) {
    final key = event.logicalKey;

    final isDirectionKey =
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown;

    if (!isDirectionKey) return KeyEventResult.ignored;

    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.handled;
    }

    final videos = _visibleVideos;
    if (videos.isEmpty) return KeyEventResult.handled;

    final currentIndex = _pendingFocusIndex ?? index;

    if (key == LogicalKeyboardKey.arrowUp) {
      widget.onNavigateUp?.call(currentIndex);
      return widget.onNavigateUp == null
          ? KeyEventResult.ignored
          : KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowDown) {
      widget.onNavigateDown?.call(currentIndex);
      return widget.onNavigateDown == null
          ? KeyEventResult.ignored
          : KeyEventResult.handled;
    }

    final targetIndex = key == LogicalKeyboardKey.arrowLeft
        ? currentIndex - 1
        : currentIndex + 1;

    if (targetIndex < 0 || targetIndex >= videos.length) {
      return KeyEventResult.ignored;
    }

    _moveToIndex(
      targetIndex,
      animate: event is KeyDownEvent,
    );

    return KeyEventResult.handled;
  }

  Future<void> _moveToIndex(
    int targetIndex, {
    required bool animate,
  }) async {
    final videos = _visibleVideos;

    if (!mounted ||
        targetIndex < 0 ||
        targetIndex >= videos.length) {
      return;
    }

    _pendingFocusIndex = targetIndex;
    final generation = ++_navigationGeneration;
    final targetNode = _focusNodeFor(targetIndex);

    if (targetNode.canRequestFocus) {
      targetNode.requestFocus();
    }

    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final viewportWidth = position.viewportDimension;
    final currentOffset = position.pixels;
    final cardWidth = _cardWidth(context);
    const spacing = AppDimensions.itemSpacing;
    const leftPadding = AppDimensions.screenHorizontal;

    final cardLeft =
        leftPadding + targetIndex * (cardWidth + spacing);
    final cardRight = cardLeft + cardWidth;

    final visibleLeft = currentOffset + leftPadding;
    final visibleRight = currentOffset + viewportWidth - leftPadding;

    double? targetOffset;

    if (cardLeft < visibleLeft) {
      targetOffset = cardLeft - leftPadding;
    } else if (cardRight > visibleRight) {
      targetOffset = cardRight - viewportWidth + leftPadding;
    }

    if (targetOffset == null) return;

    targetOffset = targetOffset
        .clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        )
        .toDouble();

    if (!mounted || generation != _navigationGeneration) return;

    if (!animate || (targetOffset - currentOffset).abs() < 1) {
      _scrollController.jumpTo(targetOffset);
    } else {
      await _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _navigationGeneration++;
    _scrollController.dispose();

    for (final node in _cardFocusNodes.values) {
      node.dispose();
    }

    _cardFocusNodes.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videos = _visibleVideos;

    if (videos.isEmpty) return const SizedBox.shrink();

    final cardHeight = _cardHeight(context);
    final rowHeight =
        cardHeight * AppDimensions.focusScale + 32;

    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppDimensions.sectionSpacing,
      ),
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
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.sectionTitle.copyWith(
                      color: AppColors.textPrimary,
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
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenHorizontal,
                vertical: 12,
              ),
              itemCount: videos.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(
                    width: AppDimensions.itemSpacing,
                  ),
              itemBuilder: (context, index) {
                final video = videos[index];

                return TvMovieCardLandscape(
                  key: ValueKey(
                    '${widget.title}_Landscape_${video.id}',
                  ),
                  video: video,
                  landscape: true,
                  focusNode: _focusNodeFor(index),
                  onKeyEvent: (node, event) =>
                      _handleCardKeyEvent(index, node, event),
                  onPressed: () =>
                      widget.onVideoPressed?.call(video),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
