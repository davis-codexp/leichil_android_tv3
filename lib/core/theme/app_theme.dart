// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// import 'app_colors.dart';

// class AppTheme {
//   AppTheme._();

//   static ThemeData get dark {
//     final baseTextTheme = ThemeData.dark().textTheme;

//     return ThemeData(
//       useMaterial3: true,
//       brightness: Brightness.dark,

//       // Global typography: Inter
//       textTheme: GoogleFonts.interTextTheme(baseTextTheme),
//       primaryTextTheme: GoogleFonts.interTextTheme(baseTextTheme),

//       scaffoldBackgroundColor: AppColors.scaffold,
//       canvasColor: AppColors.background,

//       colorScheme: const ColorScheme.dark(
//         brightness: Brightness.dark,
//         primary: AppColors.primary,
//         onPrimary: AppColors.buttonText,
//         secondary: AppColors.secondary,
//         onSecondary: AppColors.buttonText,
//         surface: AppColors.surface,
//         onSurface: AppColors.textPrimary,
//         error: AppColors.error,
//         onError: Colors.white,
//       ),

//       dividerColor: AppColors.divider,

//       splashColor: Colors.transparent,
//       highlightColor: Colors.transparent,
//       hoverColor: Colors.transparent,
//       focusColor: AppColors.focusGlow,

//       appBarTheme: const AppBarTheme(
//         backgroundColor: Colors.transparent,
//         foregroundColor: AppColors.textPrimary,
//         centerTitle: false,
//         elevation: 0,
//         scrolledUnderElevation: 0,
//       ),

//       cardTheme: CardThemeData(
//         color: AppColors.card,
//         elevation: 0,
//         margin: EdgeInsets.zero,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//       ),

//       inputDecorationTheme: InputDecorationTheme(
//         filled: true,
//         fillColor: AppColors.inputFill,
//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: 18,
//           vertical: 18,
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(color: AppColors.inputBorder),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(
//             color: AppColors.inputFocused,
//             width: 2,
//           ),
//         ),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//         ),
//       ),

//       elevatedButtonTheme: ElevatedButtonThemeData(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: AppColors.buttonPrimary,
//           foregroundColor: AppColors.buttonText,
//           elevation: 0,
//           padding: const EdgeInsets.symmetric(
//             horizontal: 24,
//             vertical: 14,
//           ),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//         ),
//       ),

//       textSelectionTheme: const TextSelectionThemeData(
//         cursorColor: AppColors.primary,
//         selectionColor: AppColors.focusGlow,
//         selectionHandleColor: AppColors.primary,
//       ),

//       progressIndicatorTheme: const ProgressIndicatorThemeData(
//         color: AppColors.primary,
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final baseTextTheme = ThemeData.dark().textTheme.apply(
      fontFamily: 'Inter',
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Global typography: locally bundled Inter
      fontFamily: 'Inter',
      textTheme: baseTextTheme,
      primaryTextTheme: baseTextTheme,

      scaffoldBackgroundColor: AppColors.scaffold,
      canvasColor: AppColors.background,

      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: AppColors.primary,
        onPrimary: AppColors.buttonText,
        secondary: AppColors.secondary,
        onSecondary: AppColors.buttonText,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: Colors.white,
      ),

      dividerColor: AppColors.divider,

      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: AppColors.focusGlow,

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),

      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.inputFocused,
            width: 2,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonPrimary,
          foregroundColor: AppColors.buttonText,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.focusGlow,
        selectionHandleColor: AppColors.primary,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
    );
  }
}
