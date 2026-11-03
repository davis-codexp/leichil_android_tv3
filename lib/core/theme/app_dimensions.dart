import 'package:flutter/material.dart';

class AppDimensions {
  AppDimensions._();

  // Screen
  static const double screenHorizontal = 64.0;
  static const double screenVertical = 24.0;

  // Sections
  static const double sectionSpacing = 8.0;
  static const double itemSpacing = 10.0;

  // Radius
  static const double radiusXS = 8.0;
  static const double radiusS = 12.0;
  static const double radiusM = 16.0;
  static const double radiusL = 22.0;
  static const double radiusXL = 28.0;

  // Backward compatibility
  static const double radiusSmall = radiusS;
  static const double radius = radiusM;
  static const double radiusLarge = radiusL;

  // Animation
  static const Duration animation = Duration(milliseconds: 180);

  // TV Focus
  static const double focusScale = 1.055;
  static const double focusBorderWidth = 3.0;

  // Posters (movie cards)
  static const double posterAspectRatio = 2 / 3;

  static double posterWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width >= 3840) return 280;
    if (width >= 2560) return 250;
    if (width >= 1920) return 220;
    if (width >= 1280) return 200;

    return 170;
  }

  static double posterHeight(BuildContext context) {
    return posterWidth(context) / posterAspectRatio;
  }

  static double movieCardHeight(BuildContext context) {
    return posterHeight(context) + 88;
  }

  // Hero banner (landscape 16:9)
  static const double bannerAspectRatio = 16 / 9;

  static double bannerHeightFor(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width / bannerAspectRatio;
  }

  // Backward compatibility for existing references
  static const double bannerHeight = 720.0;

  // Floating navigation area
  static const double headerHeight = 76.0;
}
