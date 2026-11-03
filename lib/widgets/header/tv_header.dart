import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/navigation/tv_focus_style.dart';

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
  final KeyEventResult Function(FocusNode, KeyEvent)? onKeyEvent;
  final double? focusBorderRadius;
  final bool scaleOnFocus;

  /// Builds custom content based on the current focus state.
  final Widget Function(BuildContext context, bool focused)? focusBuilder;

  @override
  State<TvFocusWrapper> createState() => _TvFocusWrapperState();
}

class _TvFocusWrapperState extends State<TvFocusWrapper> {
  bool _focused = false;

  void _handleFocusChanged(bool focused) {
    if (_focused != focused) {
      setState(() {
        _focused = focused;
      });
    }

    widget.onFocusChanged?.call(focused);
  }

  KeyEventResult _handleKeyEvent(
    FocusNode node,
    KeyEvent event,
  ) {
    final customResult = widget.onKeyEvent?.call(node, event);

    if (customResult != null &&
        customResult != KeyEventResult.ignored) {
      return customResult;
    }

    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.gameButtonA:
        if (widget.onPressed != null) {
          widget.onPressed!();
          return KeyEventResult.handled;
        }
        break;

      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.arrowRight:
        return KeyEventResult.ignored;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.focusBorderRadius ?? 10.0;

    // Use custom content when a focusBuilder is supplied.
    final content =
        widget.focusBuilder?.call(context, _focused) ?? widget.child;

    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onFocusChange: _handleFocusChanged,
      onKeyEvent: _handleKeyEvent,
      child: MouseRegion(
        onEnter: (_) {
          if (!_focused) {
            widget.focusNode?.requestFocus();
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: widget.scaleOnFocus && _focused
                ? widget.style.scale
                : 1.0,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                boxShadow: _focused
                    ? [
                        BoxShadow(
                          color: const Color(0xFF1E9AE2)
                              .withValues(alpha: 0.65),
                          blurRadius: widget.style.blur + 0.20,
                          offset: const Offset(2, 4),
                        ),
                      ]
                    : [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}