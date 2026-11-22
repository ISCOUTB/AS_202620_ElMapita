// lib/shared/theme/app_theme.dart

import 'package:flutter/material.dart';

/// Role-based color tokens. Widgets must consume roles, never raw hex values.
@immutable
class AppPalette {
  final Color background; // screen background
  final Color surface; // cards, sheets, drawers
  final Color field; // text fields
  final Color text; // primary text
  final Color textSecondary; // secondary text
  final Color action; // main action fill (buttons)
  final Color onAction;
  final Color accent; // selected states, links, accent icons
  final Color headerStart; // featured header gradient
  final Color headerEnd;
  final Color onHeader;
  final Color decorative; // decoration only, never behind small text
  final Color border;
  final Color error;
  final Color warning;
  final Color success;

  const AppPalette({
    required this.background,
    required this.surface,
    required this.field,
    required this.text,
    required this.textSecondary,
    required this.action,
    required this.onAction,
    required this.accent,
    required this.headerStart,
    required this.headerEnd,
    required this.onHeader,
    required this.decorative,
    required this.border,
    required this.error,
    required this.warning,
    required this.success,
  });

  static const light = AppPalette(
    background: Color(0xFFEEF1FA),
    surface: Color(0xFFFFFFFF),
    field: Color(0xFFF1F3FA),
    text: Color(0xFF0B1024),
    textSecondary: Color(0xFF4B536B),
    action: Color(0xFF093AD8),
    onAction: Color(0xFFFFFFFF),
    accent: Color(0xFF093AD8),
    headerStart: Color(0xFF0A1F5C),
    headerEnd: Color(0xFF005BFF),
    onHeader: Color(0xFFFFFFFF),
    decorative: Color(0xFF00B4D8),
    border: Color(0xFFD5DAEC),
    error: Color(0xFFB3261E),
    warning: Color(0xFF8A4B00),
    success: Color(0xFF1B6B3A),
  );

  static const dark = AppPalette(
    background: Color(0xFF000000),
    surface: Color(0xFF1C1C1E),
    field: Color(0xFF2C2C2E),
    text: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFAEB3C4),
    action: Color(0xFF005BFF),
    onAction: Color(0xFFFFFFFF),
    accent: Color(0xFF4D8BFF),
    headerStart: Color(0xFF0A1F5C),
    headerEnd: Color(0xFF005BFF),
    onHeader: Color(0xFFFFFFFF),
    decorative: Color(0xFF00B4D8),
    border: Color(0xFF3A3A3C),
    error: Color(0xFFFF6B6B),
    warning: Color(0xFFFFB74D),
    success: Color(0xFF5DD28A),
  );
}

/// UTB-inspired visual identity (own screens, own layout).
class AppTheme {
  AppTheme._();

  // Static aliases kept for widgets that do not read the theme yet.
  // They resolve to the LIGHT palette; prefer `AppTheme.of(context)`.
  static const Color primary = Color(0xFF093AD8);
  static const Color secondary = Color(0xFF005BFF);
  static const Color error = Color(0xFFB3261E);
  static const Color warning = Color(0xFF8A4B00);
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Palette for the active brightness.
  static AppPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppPalette.dark
          : AppPalette.light;

  /// Featured header gradient (night blue -> electric blue).
  static LinearGradient headerGradient(AppPalette p) => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [p.headerStart, p.headerEnd],
      );

  static const double radius = 16;
  static const double fieldRadius = 12;

  static ThemeData get lightTheme => _build(AppPalette.light, Brightness.light);
  static ThemeData get darkTheme => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.accent,
      onPrimary: brightness == Brightness.dark ? Colors.black : p.onAction,
      primaryContainer: p.field,
      onPrimaryContainer: p.text,
      secondary: p.headerEnd,
      onSecondary: p.onHeader,
      error: p.error,
      onError: brightness == Brightness.dark ? Colors.black : Colors.white,
      surface: p.surface,
      onSurface: p.text,
      onSurfaceVariant: p.textSecondary,
      outline: p.border,
      outlineVariant: p.border,
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      // System typography, clear titles.
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
            bodyColor: p.text,
            displayColor: p.text,
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.headerStart,
        foregroundColor: p.onHeader,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: p.onHeader,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      // One main action per screen: filled buttons use the action color.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.action,
          foregroundColor: p.onAction,
          disabledBackgroundColor: p.border,
          disabledForegroundColor: p.textSecondary,
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          shape: shape,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.action,
        foregroundColor: p.onAction,
      ),
      // Secondary actions are quiet: no brand fill.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.accent,
          side: BorderSide(color: p.border, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: shape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p.accent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.field,
        labelStyle: TextStyle(color: p.textSecondary),
        hintStyle: TextStyle(color: p.textSecondary),
        prefixIconColor: p.textSecondary,
        border: border(p.border),
        enabledBorder: border(p.border),
        focusedBorder: border(p.accent, 2),
        errorBorder: border(p.error),
        focusedErrorBorder: border(p.error, 2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        shape: shape,
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1),
      drawerTheme: DrawerThemeData(
        backgroundColor: p.headerStart,
        elevation: 0,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.textSecondary,
        textColor: p.text,
        selectedColor: p.accent,
        selectedTileColor: p.field,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.surface,
        selectedItemColor: p.accent,
        unselectedItemColor: p.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: shape,
      ),
    );
  }
}
