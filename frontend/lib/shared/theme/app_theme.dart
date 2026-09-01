// lib/shared/theme/app_theme.dart

import 'package:flutter/material.dart';

/// Paleta institucional UTB — estilo Flat Corporativo / Wayfinding.
class AppTheme {
  // Paleta base (de más clara a más oscura)
  static const Color aliceBlue = Color(0xFFE3F2FD);
  static const Color icyBlue = Color(0xFFBBDEFB);
  static const Color skyBlue = Color(0xFF90CAF9);
  static const Color coolSky = Color(0xFF64B5F6);
  static const Color dodgerBlue = Color(0xFF2196F3);
  static const Color brilliantAzure = Color(0xFF1E88E5);
  static const Color cornflowerOcean = Color(0xFF1976D2);
  static const Color oceanDeep = Color(0xFF1565C0);
  static const Color cobaltBlue = Color(0xFF0D47A1);

  // Roles semánticos
  static const Color primary = cobaltBlue;
  static const Color primaryPressed = oceanDeep;
  static const Color secondary = brilliantAzure;
  static const Color accent = dodgerBlue;
  static const Color selectedTint = aliceBlue;
  static const Color selectedAccent = cornflowerOcean;
  static const Color divider = icyBlue;
  static const Color inactiveIcon = skyBlue;

  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF57C00);
  static const Color surface = Colors.white;
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.white;
  static const Color onSurface = Color(0xFF1A1A1A);
  static const Color onError = Colors.white;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: surface,
      colorScheme: const ColorScheme.light(
        primary: primary,
        primaryContainer: aliceBlue,
        secondary: secondary,
        error: error,
        surface: surface,
        onPrimary: onPrimary,
        onSecondary: onSecondary,
        onSurface: onSurface,
        onError: onError,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: icyBlue,
          minimumSize: const Size(double.infinity, 48),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: divider),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      dividerTheme: const DividerThemeData(color: divider, thickness: 1),
      drawerTheme: const DrawerThemeData(
        backgroundColor: surface,
        elevation: 0,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: onSurface,
        selectedColor: selectedAccent,
        selectedTileColor: selectedTint,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: const ColorScheme.dark(
        primary: skyBlue,
        primaryContainer: oceanDeep,
        secondary: coolSky,
        error: error,
        surface: Color(0xFF1E1E1E),
        onPrimary: Color(0xFF00204A),
        onSecondary: Color(0xFF00204A),
        onSurface: Colors.white,
        onError: Color(0xFF00204A),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0A1F3D),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: skyBlue,
          foregroundColor: const Color(0xFF00204A),
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        elevation: 0,
      ),
    );
  }
}
