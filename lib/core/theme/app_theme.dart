import 'package:flutter/material.dart';

class RgColors {
  RgColors._();
  static const navy = Color(0xFF070E1C);
  static const panel = Color(0xFF0F1A2E);
  static const panelHi = Color(0xFF16243E);
  static const line = Color(0xFF223454);
  static const blue = Color(0xFF3B82F6);
  static const red = Color(0xFFE5303A);
  static const redDeep = Color(0xFFB0121C);
  static const green = Color(0xFF22C55E);
  static const amber = Color(0xFFF5A524);
  static const yellow = Color(0xFFFACC15);
  static const orange = Color(0xFFF97316);
  static const text = Color(0xFFE8EEF8);
  static const muted = Color(0xFF8A9BB8);
}

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: RgColors.blue,
      brightness: Brightness.dark,
    ).copyWith(
      primary: RgColors.blue,
      secondary: RgColors.red,
      error: RgColors.red,
      surface: RgColors.panel,
      onSurface: RgColors.text,
      surfaceContainerHighest: RgColors.panelHi,
      outline: RgColors.line,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return base.copyWith(
      scaffoldBackgroundColor: RgColors.navy,
      appBarTheme: const AppBarTheme(
        backgroundColor: RgColors.navy,
        foregroundColor: RgColors.text,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: RgColors.panel,
        indicatorColor: RgColors.blue.withValues(alpha: 0.25),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 68,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: RgColors.panelHi,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      textTheme: base.textTheme.apply(bodyColor: RgColors.text, displayColor: RgColors.text),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      dividerColor: RgColors.line,
    );
  }

  /// Tabular figures so timers / ETAs don't jitter while ticking.
  static const mono = TextStyle(fontFeatures: [FontFeature.tabularFigures()]);
}
