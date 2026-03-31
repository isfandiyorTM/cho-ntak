import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN SYSTEM
// Dark  → deep navy-black base, warm amber accent, soft card surfaces
// Light → cool white base, deep navy as primary, amber as accent only
// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  // ── Amber / Gold — primary brand accent ──────────────────────────────
  static const Color amber       = Color(0xFFF0B429); // warmer, less "bling"
  static const Color amberLight  = Color(0xFFFCD34D);
  static const Color amberDark   = Color(0xFFD97706);
  static const Color amberDim    = Color(0xFF92400E);

  // Alias so existing code using AppColors.gold still works
  static const Color gold        = amber;
  static const Color goldLight   = amberLight;
  static const Color goldDark    = amberDark;
  static const Color goldDim     = amberDim;

  // ── Dark palette — deep navy-black, premium feel ──────────────────────
  static const Color bgDark      = Color(0xFF0F1117); // navy-black, not pure black
  static const Color surfaceDark = Color(0xFF161B26); // header / nav surface
  static const Color cardDark    = Color(0xFF1C2333); // card background
  static const Color borderDark  = Color(0xFF2A3347); // subtle border
  static const Color mutedDark   = Color(0xFF64748B); // muted text

  // ── Light palette — cool whites, trustworthy ─────────────────────────
  static const Color bgLight      = Color(0xFFF4F6FA); // cool grey-white
  static const Color surfaceLight = Color(0xFFFFFFFF); // pure white panels
  static const Color cardLight    = Color(0xFFF8FAFC); // very slight blue tint
  static const Color borderLight  = Color(0xFFE2E8F0); // slate border
  static const Color navyText     = Color(0xFF1E293B); // deep navy for text
  static const Color mutedLight   = Color(0xFF94A3B8); // slate muted text

  // ── Semantic ──────────────────────────────────────────────────────────
  static const Color income      = Color(0xFF22C55E); // vibrant green
  static const Color expense     = Color(0xFFF87171); // soft coral red
  static const Color warning     = Color(0xFFFBBF24); // amber warning

  // ── Category palette ─────────────────────────────────────────────────

  // ── Aliases for files using older/different naming ───────────────────
  static const Color accent       = amber;       // AppColors.accent → amber
  static const Color brand        = amber;       // AppColors.brand  → amber
  static const Color textDark     = Colors.white;           // dark mode text
  static const Color textLight    = navyText;               // light mode text
  static const Color subTextDark  = mutedDark;              // dark muted
  static const Color subTextLight = mutedLight;             // light muted
  static const List<Color> categoryColors = [
    Color(0xFFF0B429), Color(0xFF22C55E), Color(0xFFF87171),
    Color(0xFF60A5FA), Color(0xFFA78BFA), Color(0xFFFB923C),
    Color(0xFF34D399), Color(0xFFF472B6), Color(0xFF4ADE80),
    Color(0xFFFF6B6B),
  ];
}

class AppTheme {
  AppTheme._();

  // ── System UI overlay — called on every theme switch ─────────────────
  static void applySystemUI(bool isDark) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
      isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor:
      isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      systemNavigationBarIconBrightness:
      isDark ? Brightness.light : Brightness.dark,
    ));
  }

  // ─────────────────────────────────────────────────────────────────────
  // DARK THEME
  // ─────────────────────────────────────────────────────────────────────
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgDark,
    colorScheme: const ColorScheme.dark(
      primary:        AppColors.amber,
      secondary:      AppColors.amberLight,
      surface:        AppColors.surfaceDark,
      error:          AppColors.expense,
      onPrimary:      Colors.black,
      onSurface:      Colors.white,
      onSurfaceVariant: AppColors.mutedDark,
    ),
    textTheme: const TextTheme(
      displayLarge:  TextStyle(color: Colors.white,  fontWeight: FontWeight.w900),
      displayMedium: TextStyle(color: Colors.white,  fontWeight: FontWeight.w800),
      titleLarge:    TextStyle(color: Colors.white,  fontWeight: FontWeight.w700, fontSize: 20),
      titleMedium:   TextStyle(color: Colors.white,  fontWeight: FontWeight.w600, fontSize: 16),
      titleSmall:    TextStyle(color: Colors.white,  fontWeight: FontWeight.w600, fontSize: 14),
      bodyLarge:     TextStyle(color: Colors.white,  fontWeight: FontWeight.w400, fontSize: 16),
      bodyMedium:    TextStyle(color: Color(0xFFCBD5E1), fontWeight: FontWeight.w400, fontSize: 14),
      bodySmall:     TextStyle(color: AppColors.mutedDark, fontWeight: FontWeight.w400, fontSize: 12),
      labelLarge:    TextStyle(color: Colors.white,  fontWeight: FontWeight.w700, fontSize: 14),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
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
      fillColor: AppColors.cardDark,
      labelStyle: const TextStyle(color: AppColors.mutedDark),
      hintStyle: const TextStyle(color: AppColors.mutedDark),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.amber, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.expense),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.amber,
        foregroundColor: Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
            fontWeight: FontWeight.w800, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.amber,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.amber,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(
        color: AppColors.borderDark, thickness: 1),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      selectedItemColor: AppColors.amber,
      unselectedItemColor: AppColors.mutedDark,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
      s.contains(WidgetState.selected)
          ? AppColors.amber
          : AppColors.mutedDark),
      trackColor: WidgetStateProperty.resolveWith((s) =>
      s.contains(WidgetState.selected)
          ? AppColors.amber.withValues(alpha: 0.35)
          : AppColors.borderDark),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.amber,
      thumbColor: AppColors.amber,
      inactiveTrackColor: AppColors.borderDark,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.cardDark,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.cardDark,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.cardDark,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.amber,
      linearTrackColor: AppColors.borderDark,
    ),
  );

  // ─────────────────────────────────────────────────────────────────────
  // LIGHT THEME — cool white, deep navy, amber accents
  // ─────────────────────────────────────────────────────────────────────
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.bgLight,
    colorScheme: const ColorScheme.light(
      primary:        AppColors.navyText,
      secondary:      AppColors.amberDark,
      surface:        AppColors.surfaceLight,
      error:          AppColors.expense,
      onPrimary:      Colors.white,
      onSurface:      AppColors.navyText,
      onSurfaceVariant: AppColors.mutedLight,
    ),
    textTheme: const TextTheme(
      displayLarge:  TextStyle(color: AppColors.navyText, fontWeight: FontWeight.w900),
      displayMedium: TextStyle(color: AppColors.navyText, fontWeight: FontWeight.w800),
      titleLarge:    TextStyle(color: AppColors.navyText, fontWeight: FontWeight.w700, fontSize: 20),
      titleMedium:   TextStyle(color: AppColors.navyText, fontWeight: FontWeight.w600, fontSize: 16),
      titleSmall:    TextStyle(color: AppColors.navyText, fontWeight: FontWeight.w600, fontSize: 14),
      bodyLarge:     TextStyle(color: AppColors.navyText, fontWeight: FontWeight.w400, fontSize: 16),
      bodyMedium:    TextStyle(color: Color(0xFF475569),  fontWeight: FontWeight.w400, fontSize: 14),
      bodySmall:     TextStyle(color: AppColors.mutedLight, fontWeight: FontWeight.w400, fontSize: 12),
      labelLarge:    TextStyle(color: AppColors.navyText, fontWeight: FontWeight.w700, fontSize: 14),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surfaceLight,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: AppColors.navyText),
      titleTextStyle: TextStyle(
        color: AppColors.navyText,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
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
      fillColor: AppColors.surfaceLight,
      labelStyle: const TextStyle(color: AppColors.mutedLight),
      hintStyle: const TextStyle(color: AppColors.mutedLight),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.navyText, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.expense),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.navyText,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
            fontWeight: FontWeight.w800, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.navyText,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.navyText,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(
        color: AppColors.borderLight, thickness: 1),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceLight,
      selectedItemColor: AppColors.navyText,
      unselectedItemColor: AppColors.mutedLight,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
      s.contains(WidgetState.selected)
          ? AppColors.navyText
          : Colors.white),
      trackColor: WidgetStateProperty.resolveWith((s) =>
      s.contains(WidgetState.selected)
          ? AppColors.navyText.withValues(alpha: 0.8)
          : AppColors.borderLight),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.navyText,
      thumbColor: AppColors.navyText,
      inactiveTrackColor: AppColors.borderLight,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceLight,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.surfaceLight,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.borderLight)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.navyText,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.navyText,
      linearTrackColor: AppColors.borderLight,
    ),
  );
}