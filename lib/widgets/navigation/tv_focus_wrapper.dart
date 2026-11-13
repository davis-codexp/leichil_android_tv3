import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tv_focus_style.dart';

class TvFocusWrapper extends StatefulWidget {
  const TvFocusWrapper({
    super.key,
    required this.child,
    this.onPressed,
    this.style = TvFocusStyle.card,
    this.autofocus = false,
    this.focusNode,
    this.onFocusChanged,
    this.onKeyEvent,
    this.focusBorderRadius,
    this.scaleOnFocus = true,
    this.focusBuilder,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final TvFocusStyle style;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<bool>? onFocusChanged;
  final FocusOnKeyEventCallback? onKeyEvent;
  final double? focusBorderRadius;
  final bool scaleOnFocus;
  final Widget Function(BuildContext context, bool focused)? focusBuilder;

  @override
  State<TvFocusWrapper> createState() => _TvFocusWrapperState();
}

class _TvFocusWrapperState extends State<TvFocusWrapper> {
  FocusNode? _internalFocusNode;
  bool _focused = false;

  FocusNode get _focusNode =>
      widget.focusNode ??
      (_internalFocusNode ??= FocusNode(debugLabel: 'TvFocus'));

  @override
  void dispose() {
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _handleFocusChanged(bool focused) {
    if (_focused == focused) return;

    setState(() => _focused = focused);
    widget.onFocusChanged?.call(focused);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final customHandler = widget.onKeyEvent;

    if (customHandler != null) {
      final result = customHandler(node, event);

      if (result != KeyEventResult.ignored) {
        return result;
      }
    }

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.gameButtonA) {
      widget.onPressed?.call();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.browserBack ||
        key == LogicalKeyboardKey.backspace) {
      return KeyEventResult.ignored;
    }

    TraversalDirection? direction;

    if (key == LogicalKeyboardKey.arrowLeft) {
      direction = TraversalDirection.left;
    } else if (key == LogicalKeyboardKey.arrowRight) {
      direction = TraversalDirection.right;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      direction = TraversalDirection.up;
    } else if (key == LogicalKeyboardKey.arrowDown) {
      direction = TraversalDirection.down;
    }

    if (direction != null) {
      final moved = node.focusInDirection(direction);
      return moved ? KeyEventResult.handled : KeyEventResult.ignored;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 170);

    final radius = widget.focusBorderRadius ?? widget.style.borderRadius;

    final child = widget.focusBuilder?.call(context, _focused) ?? widget.child;

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onFocusChange: _handleFocusChanged,
      onKeyEvent: _handleKeyEvent,
      child: MouseRegion(
        cursor: widget.onPressed == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: widget.onPressed,
          child: AnimatedScale(
            duration: duration,
            curve: Curves.easeOutCubic,
            scale: _focused && widget.scaleOnFocus
                ? widget.style.scale.clamp(1.0, 1.07).toDouble()
                : 1.0,
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(0, _focused ? -3.0 : 0.0, 0),
              transformAlignment: Alignment.center,
              // decoration:
              // BoxDecoration(
              //   color: _focused ? const Color(0xFF555555) : Colors.transparent,
              //   borderRadius: BorderRadius.circular(radius),
              //   border: Border.all(
              //     color: _focused
              //         ? const Color(0xFFD0D0D0)
              //         : Colors.transparent,
              //     width: _focused ? 2.0 : 0,
              //   ),
              //   boxShadow: _focused
              //       ? [
              //           // Blue focus glow
              //           BoxShadow(
              //             color: const Color(
              //               0xFF1E9AE2,
              //             ).withValues(alpha: 0.65),
              //             blurRadius: widget.style.blur + 0.20,
              //             spreadRadius: 2,
              //             offset: const Offset(0, 2),
              //           ),
              //         ]
              //       : const [],
              // ),
              decoration: BoxDecoration(
                color: _focused ? const Color(0xFF555555) : Colors.transparent,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: _focused
                      ? widget.style.borderColor
                      : Colors.transparent,
                  width: _focused ? widget.style.borderWidth : 0,
                ),
                boxShadow:
                    _focused && widget.style.glowColor != Colors.transparent
                    ? [
                        BoxShadow(
                          color: widget.style.glowColor,
                          blurRadius: widget.style.blur,
                          spreadRadius: widget.style.spread,
                        ),
                      ]
                    : const [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
