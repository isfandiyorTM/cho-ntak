import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color gold        = Color(0xFFFFD700);
  static const Color goldLight   = Color(0xFFFFE55C);
  static const Color goldDark    = Color(0xFFB8960C);
  static const Color goldDim     = Color(0xFF8B6914);

  static const Color bgDark      = Color(0xFF0A0A0A);
  static const Color surfaceDark = Color(0xFF141414);
  static const Color cardDark    = Color(0xFF1C1C1C);
  static const Color borderDark  = Color(0xFF2A2A2A);

  static const Color bgLight     = Color(0xFFFAFAFA);
  static const Color surfaceLight= Color(0xFFFFFFFF);
  static const Color cardLight   = Color(0xFFF5F5F5);
  static const Color borderLight = Color(0xFFE0E0E0);

  static const Color income      = Color(0xFF4CAF50);
  static const Color expense     = Color(0xFFEF5350);
  static const Color warning     = Color(0xFFFF9800);

  static const List<Color> categoryColors = [
    Color(0xFFFFD700), Color(0xFF4CAF50), Color(0xFFEF5350),
    Color(0xFF2196F3), Color(0xFF9C27B0), Color(0xFFFF9800),
    Color(0xFF00BCD4), Color(0xFFE91E63), Color(0xFF8BC34A),
    Color(0xFFFF5722),
  ];
}

class AppTheme {
  AppTheme._();

  // Use system font (Roboto on Android) — guaranteed to work in release
  static const _textThemeDark = TextTheme(
    displayLarge:  TextStyle(fontWeight: FontWeight.w800),
    displayMedium: TextStyle(fontWeight: FontWeight.w700),
    titleLarge:    TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
    titleMedium:   TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
    titleSmall:    TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    bodyLarge:     TextStyle(fontWeight: FontWeight.w400, fontSize: 16),
    bodyMedium:    TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
    bodySmall:     TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
    labelLarge:    TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
  );

  static const _textThemeLight = TextTheme(
    displayLarge:  TextStyle(fontWeight: FontWeight.w800, color: Colors.black),
    displayMedium: TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
    titleLarge:    TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: Colors.black),
    titleMedium:   TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87),
    titleSmall:    TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
    bodyLarge:     TextStyle(fontWeight: FontWeight.w400, fontSize: 16, color: Colors.black87),
    bodyMedium:    TextStyle(fontWeight: FontWeight.w400, fontSize: 14, color: Colors.black87),
    bodySmall:     TextStyle(fontWeight: FontWeight.w400, fontSize: 12, color: Colors.black54),
    labelLarge:    TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgDark,
    colorScheme: const ColorScheme.dark(
      primary:   AppColors.gold,
      secondary: AppColors.goldLight,
      surface:   AppColors.surfaceDark,
      error:     AppColors.expense,
    ),
    textTheme: _textThemeDark,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgDark,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: AppColors.gold),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderDark),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.gold, width: 2),
      ),
      labelStyle: const TextStyle(color: AppColors.goldDim),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        textStyle:
        const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.gold,
      foregroundColor: Colors.black,
      elevation: 4,
    ),
    dividerTheme: const DividerThemeData(
        color: AppColors.borderDark, thickness: 1),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      selectedItemColor: AppColors.gold,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected)
              ? AppColors.gold
              : Colors.grey),
      trackColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected)
              ? AppColors.gold.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.3)),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.gold,
      thumbColor: AppColors.gold,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.cardDark,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.cardDark,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
    ),
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.bgLight,
    colorScheme: const ColorScheme.light(
      primary:   AppColors.goldDark,
      secondary: AppColors.gold,
      surface:   AppColors.surfaceLight,
      error:     AppColors.expense,
    ),
    textTheme: _textThemeLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgLight,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: AppColors.goldDark),
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderLight),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
        const BorderSide(color: AppColors.goldDark, width: 2),
      ),
      labelStyle: const TextStyle(color: AppColors.goldDim),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.goldDark,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        textStyle:
        const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.goldDark,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    dividerTheme: const DividerThemeData(
        color: AppColors.borderLight, thickness: 1),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceLight,
      selectedItemColor: AppColors.goldDark,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected)
              ? AppColors.goldDark
              : Colors.grey),
      trackColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected)
              ? AppColors.goldDark.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.3)),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.goldDark,
      thumbColor: AppColors.goldDark,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
    ),
  );
}