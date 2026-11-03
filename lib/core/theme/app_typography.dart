import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  // Hero
  static const TextStyle heroEyebrow = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    letterSpacing: 1.8,
  );

  static const TextStyle heroTitle = TextStyle(
    fontSize: 58,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.04,
    letterSpacing: -1.2,
  );

  static const TextStyle heroSubtitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  // Screen
  static const TextStyle screenTitle = TextStyle(
    fontSize: 38,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  // Sections
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.45,
  );

  static const TextStyle sectionAction = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // Navigation
  static const TextStyle navItem = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle navItemFocused = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // Movie cards
  static const TextStyle cardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle cardMeta = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  // Badges
  static const TextStyle badge = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    letterSpacing: 0.7,
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 18,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    color: AppColors.textMuted,
    height: 1.4,
  );

  // Buttons
  static const TextStyle button = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.buttonText,
  );

  // Captions
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );
}
