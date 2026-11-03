import 'package:flutter/material.dart';

class TvHorizontalListController {
  TvHorizontalListController({
    this.itemExtent = 250,
    this.itemSpacing = 18,
    this.animationDuration = const Duration(milliseconds: 180),
  }) : scrollController = ScrollController();

  final ScrollController scrollController;
  final double itemExtent;
  final double itemSpacing;
  final Duration animationDuration;

  int focusedIndex = 0;
  int _requestId = 0;

  Future<void> scrollToIndex(
    BuildContext context,
    int index, {
    bool animate = true,
    double leadingPadding = 0,
  }) async {
    if (index < 0) return;
    focusedIndex = index;
    if (!scrollController.hasClients) return;

    final requestId = ++_requestId;
    final position = scrollController.position;
    final viewportWidth = position.viewportDimension;
    final stride = itemExtent + itemSpacing;
    final itemStart = leadingPadding + index * stride;
    final itemEnd = itemStart + itemExtent;
    final current = position.pixels;

    double target = current;
    if (itemStart < current + 24) {
      target = itemStart - 24;
    } else if (itemEnd > current + viewportWidth - 24) {
      target = itemEnd - viewportWidth + 24;
    }

    target = target.clamp(0.0, position.maxScrollExtent).toDouble();
    if ((target - current).abs() < 1) return;

    try {
      if (animate) {
        await scrollController.animateTo(
          target,
          duration: animationDuration,
          curve: Curves.easeOutCubic,
        );
      } else {
        scrollController.jumpTo(target);
      }
    } catch (_) {
      // A row can be disposed while navigation is in flight.
      return;
    }
    if (requestId != _requestId) return;
  }

  void cancelPendingScroll() {
    _requestId++;
  }

  void dispose() {
    cancelPendingScroll();
    scrollController.dispose();
  }
}
