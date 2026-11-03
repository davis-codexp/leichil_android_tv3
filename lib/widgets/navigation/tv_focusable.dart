import 'package:flutter/material.dart';
import 'tv_focus_style.dart';
import 'tv_focus_wrapper.dart';

/// A small, reusable TV focus surface for buttons, menu items and cards.
class TvFocusable extends StatelessWidget {
  const TvFocusable({
    super.key,
    required this.child,
    this.focusNode,
    this.autofocus = false,
    this.style = TvFocusStyle.card,
    this.onPressed,
    this.onFocusChanged,
    this.onKeyEvent,
    this.scaleOnFocus = true,
  });

  final Widget child;
  final FocusNode? focusNode;
  final bool autofocus;
  final TvFocusStyle style;
  final VoidCallback? onPressed;
  final ValueChanged<bool>? onFocusChanged;
  final FocusOnKeyEventCallback? onKeyEvent;
  final bool scaleOnFocus;

  @override
  Widget build(BuildContext context) => TvFocusWrapper(
    focusNode: focusNode,
    autofocus: autofocus,
    style: style,
    onPressed: onPressed,
    onFocusChanged: onFocusChanged,
    onKeyEvent: onKeyEvent,
    scaleOnFocus: scaleOnFocus,
    child: child,
  );
}
