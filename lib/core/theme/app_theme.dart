import 'package:flutter/material.dart';
import 'package:help_ride/core/constants/app_constants.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData light(AppRole role) {
    return _baseTheme(
      brightness: Brightness.light,
      bg: AppColors.lightBg,
      surface: AppColors.lightSurface,
      text: AppColors.lightText,
      muted: AppColors.lightMuted,
      primary: _primaryFor(role),
    );
  }

  static ThemeData dark(AppRole role) {
    return _baseTheme(
      brightness: Brightness.dark,
      bg: AppColors.darkBg,
      surface: AppColors.darkSurface,
      text: AppColors.darkText,
      muted: AppColors.darkMuted,
      primary: _primaryFor(role),
    );
  }

  static Color _primaryFor(AppRole role) {
    switch (role) {
      case AppRole.driver:
        return AppColors.driverPrimary;
      case AppRole.passenger:
      default:
        return AppColors.passengerPrimary;
    }
  }

  static ThemeData _baseTheme({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required Color text,
    required Color muted,
    required Color primary,
  }) {
    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorSchemeSeed: primary,
    );

    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        surface: surface,
        error: AppColors.error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
      ),
      textTheme: base.textTheme.apply(bodyColor: text, displayColor: text),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: muted),
        labelStyle: TextStyle(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
