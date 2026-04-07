import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand greens – money flow
  static const green50 = Color(0xFFE8F5E9);
  static const green100 = Color(0xFFC8E6C9);
  static const green500 = Color(0xFF4CAF50);
  static const green600 = Color(0xFF43A047);
  static const green700 = Color(0xFF388E3C);

  // Reds – dues / alerts
  static const red50 = Color(0xFFFFEBEE);
  static const red400 = Color(0xFFEF5350);
  static const red600 = Color(0xFFE53935);

  // Amber – warnings
  static const amber50 = Color(0xFFFFF8E1);
  static const amber400 = Color(0xFFFFCA28);
  static const amber600 = Color(0xFFFFB300);

  // Blue – UPI
  static const blue50 = Color(0xFFE3F2FD);
  static const blue500 = Color(0xFF2196F3);
  static const blue600 = Color(0xFF1E88E5);

  // WhatsApp
  static const waGreen = Color(0xFF25D366);

  // Surface
  static const surface = Color(0xFFF6F7FB);
  static const surfaceDark = Color(0xFF1A1C1E);
  static const cardDark = Color(0xFF2C2E33);
}

ThemeData lightTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.green600,
    onPrimary: Colors.white,
    primaryContainer: AppColors.green50,
    onPrimaryContainer: AppColors.green700,
    secondary: AppColors.blue600,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.blue50,
    onSecondaryContainer: AppColors.blue600,
    error: AppColors.red600,
    onError: Colors.white,
    errorContainer: AppColors.red50,
    onErrorContainer: AppColors.red600,
    surface: AppColors.surface,
    onSurface: Color(0xFF1A1C1E),
    surfaceContainerHighest: Color(0xFFE8EAED),
    outline: Color(0xFFBDBDBD),
    outlineVariant: Color(0xFFE0E0E0),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: GoogleFonts.notoSansTextTheme().apply(
      bodyColor: const Color(0xFF1A1C1E),
      displayColor: const Color(0xFF1A1C1E),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1A1C1E),
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      titleTextStyle: GoogleFonts.notoSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1A1C1E),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.green600,
      unselectedItemColor: Color(0xFF9E9E9E),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF0F2F5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.green600, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.green600,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.notoSans(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.green600,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.notoSans(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFF0F2F5), thickness: 1),
    scaffoldBackgroundColor: AppColors.surface,
  );
}

ThemeData darkTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.green500,
    onPrimary: Colors.black,
    primaryContainer: Color(0xFF1B3A1C),
    onPrimaryContainer: AppColors.green100,
    secondary: AppColors.blue500,
    onSecondary: Colors.black,
    secondaryContainer: Color(0xFF0D2137),
    onSecondaryContainer: Color(0xFF90CAF9),
    error: Color(0xFFEF9A9A),
    onError: Colors.black,
    errorContainer: Color(0xFF4A1515),
    onErrorContainer: Color(0xFFEF9A9A),
    surface: AppColors.surfaceDark,
    onSurface: Color(0xFFE3E3E3),
    surfaceContainerHighest: Color(0xFF2E3035),
    outline: Color(0xFF444749),
    outlineVariant: Color(0xFF2E3035),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: GoogleFonts.notoSansTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: const Color(0xFFE3E3E3),
      displayColor: const Color(0xFFE3E3E3),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surfaceDark,
      foregroundColor: const Color(0xFFE3E3E3),
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      titleTextStyle: GoogleFonts.notoSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: const Color(0xFFE3E3E3),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.cardDark,
      selectedItemColor: AppColors.green500,
      unselectedItemColor: Color(0xFF757575),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2E3035),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.green500, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFF2E3035), thickness: 1),
    scaffoldBackgroundColor: AppColors.surfaceDark,
  );
}
