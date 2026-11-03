import 'package:flutter/material.dart';

@immutable
class TvFocusStyle {
  const TvFocusStyle({
    required this.scale,
    required this.borderRadius,
    required this.borderWidth,
    required this.borderColor,
    required this.glowColor,
    required this.blur,
    required this.spread,
  });

  final double scale;
  final double borderRadius;
  final double borderWidth;
  final Color borderColor;
  final Color glowColor;
  final double blur;
  final double spread;

  static const TvFocusStyle card = TvFocusStyle(
    scale: 1.045,
    borderRadius: 10,
    borderWidth: 0,
    borderColor: Colors.transparent,
    glowColor: Colors.transparent,
    blur: 10,
    spread: 0,
  );

  static const TvFocusStyle menu = TvFocusStyle(
    scale: 1.02,
    borderRadius: 24,
    borderWidth: 0,
    borderColor: Colors.transparent,
    glowColor: Colors.transparent,
    blur: 8,
    spread: 0,
  );

  static const TvFocusStyle button = TvFocusStyle(
    scale: 1.035,
    borderRadius: 12,
    borderWidth: 0,
    borderColor: Colors.transparent,
    glowColor: Colors.transparent,
    blur: 8,
    spread: 0,
  );
}
