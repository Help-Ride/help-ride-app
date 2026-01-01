import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  // Private constructor to prevent instantiation
  AppTextStyles._();

  // Base text style using Arimo font
  static TextStyle _baseStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.arimo(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // ==================== HEADINGS ====================

  /// Heading 1 - 32px, Semi-Bold
  static TextStyle h1({Color? color}) => _baseStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: color ?? Colors.black87,
  );

  /// Heading 2 - 30px, Regular
  static TextStyle h2({Color? color}) => _baseStyle(
    fontSize: 30,
    fontWeight: FontWeight.w400,
    color: color ?? Colors.black87,
  );

  /// Heading 3 - 24px, Medium
  static TextStyle h3({Color? color}) => _baseStyle(
    fontSize: 24,
    fontWeight: FontWeight.w500,
    color: color ?? Colors.black87,
  );

  /// Heading 4 - 20px, Medium
  static TextStyle h4({Color? color}) => _baseStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: color ?? Colors.black87,
  );

  /// Heading 5 - 18px, Medium
  static TextStyle h5({Color? color}) => _baseStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: color ?? Colors.black87,
  );

  // ==================== BODY TEXT ====================

  /// Body Large - 16px, Regular
  static TextStyle bodyLarge({Color? color}) => _baseStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: color ?? Colors.black87,
  );

  /// Body Medium - 14px, Regular (Default)
  static TextStyle bodyMedium({Color? color}) => _baseStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: color ?? Colors.black87,
  );

  /// Body Small - 12px, Regular
  static TextStyle bodySmall({Color? color}) => _baseStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: color ?? Colors.grey[600],
  );

  // ==================== LABELS ====================

  /// Label Large - 14px, Medium
  static TextStyle labelLarge({Color? color}) => _baseStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: color ?? Colors.grey[800],
  );

  /// Label Medium - 12px, Medium
  static TextStyle labelMedium({Color? color}) => _baseStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: color ?? Colors.grey[700],
  );

  /// Label Small - 11px, Medium
  static TextStyle labelSmall({Color? color}) => _baseStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: color ?? Colors.grey[600],
  );

  // ==================== BUTTONS ====================

  /// Button Large - 16px, Semi-Bold
  static TextStyle buttonLarge({Color? color}) => _baseStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: color ?? Colors.white,
  );

  /// Button Medium - 14px, Regular
  static TextStyle buttonMedium({Color? color}) => _baseStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: color ?? Colors.white,
  );

  /// Button Small - 12px, Medium
  static TextStyle buttonSmall({Color? color}) => _baseStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: color ?? Colors.white,
  );

  // ==================== SPECIAL STYLES ====================

  /// Subtitle - 16px, Regular, Muted
  static TextStyle subtitle({Color? color}) => _baseStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: color ?? Colors.grey[600],
  );

  /// Caption - 12px, Regular, Muted
  static TextStyle caption({Color? color}) => _baseStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: color ?? Colors.grey[600],
    height: 1.5,
  );

  /// Overline - 10px, Medium, Uppercase
  static TextStyle overline({Color? color}) => _baseStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: color ?? Colors.grey[600],
    letterSpacing: 1.5,
  );

  /// Link - 14px, Medium, Primary Color
  static TextStyle link({Color? color}) => _baseStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: color ?? const Color(0xFF00C689),
  );

  /// Error Text - 14px, Regular, Error Color
  static TextStyle error({Color? color}) => _baseStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: color ?? Colors.red,
  );

  /// Success Text - 14px, Regular, Success Color
  static TextStyle success({Color? color}) => _baseStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: color ?? const Color(0xFF00C689),
  );

  /// Hint Text - 14px, Regular, Light Grey
  static TextStyle hint({Color? color}) => _baseStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: color ?? Colors.grey[400],
  );

  // ==================== CUSTOM MODIFIERS ====================

  /// Apply bold weight to any style
  static TextStyle bold(TextStyle style) {
    return style.copyWith(fontWeight: FontWeight.w700);
  }

  /// Apply semi-bold weight to any style
  static TextStyle semiBold(TextStyle style) {
    return style.copyWith(fontWeight: FontWeight.w600);
  }

  /// Apply medium weight to any style
  static TextStyle medium(TextStyle style) {
    return style.copyWith(fontWeight: FontWeight.w500);
  }

  /// Apply italic to any style
  static TextStyle italic(TextStyle style) {
    return style.copyWith(fontStyle: FontStyle.italic);
  }

  /// Apply underline to any style
  static TextStyle underline(TextStyle style) {
    return style.copyWith(decoration: TextDecoration.underline);
  }

  /// Apply line-through to any style
  static TextStyle lineThrough(TextStyle style) {
    return style.copyWith(decoration: TextDecoration.lineThrough);
  }

  /// Apply custom color to any style
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Apply custom opacity to any style
  static TextStyle withOpacity(TextStyle style, double opacity) {
    return style.copyWith(color: style.color?.withOpacity(opacity));
  }
}