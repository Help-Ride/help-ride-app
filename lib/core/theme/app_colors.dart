import 'package:flutter/material.dart';

class AppColors {
  // Brand by role
  static const passengerPrimary = Color(0xFF00BC7D); // green
  static const driverPrimary = Color(0xFF2B7FFF); // blue

  // ---------- DARK ----------
  static const darkBg = Color(0xFF0B0B0F);
  static const darkSurface = Color(0xFF13131A);
  static const darkText = Color(0xFFEDEDF4);
  static const darkMuted = Color(0xFF9A9AA6);

  // ---------- LIGHT ----------
  static const lightBg = Color(0xFFF7F7FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightText = Color(0xFF111111);
  static const lightMuted = Color(0xFF6B7280);

  static const error = Color(0xFFFF4D4D);

  // ---------- LOGIN SCREEN SPECIFIC ----------
  // Background gradient colors
  static const gradientStart = Color(0xFFF0FDF9); // Light mint/teal
  static const gradientEnd = Color(0xFFE8F5F1); // Slightly darker mint

  // Input fields
  static const inputBackground = Color(0xFFF9FAFB); // Very light gray
  static const inputBorder = Color(0xFFE2E6EF); // Light gray border
  static const inputPlaceholder = Color(0xFF9CA3AF); // Gray placeholder text

  // Button gradient (Green button)
  static const buttonGradientStart = Color(0xFF00D98A); // Bright green
  static const buttonGradientEnd = Color(0xFF00BC7D); // Darker green
  static const buttonShadow = Color(0x2600BC7D); // 15% opacity green shadow

  // Text colors
  static const lightMutedSecondary = Color(0xFF6B7280); // Subtitle gray
  static const termsText = Color(0xFF9CA3AF); // Terms text gray

  // OAuth buttons
  static const oauthBorder = Color(0xFFE5E7EB); // Border for Google/Apple
  static const oauthText = Color(0xFF374151); // Text in OAuth buttons

  // Icons
  static const iconGray = Color(0xFF9CA3AF); // Eye icon color

  // Links
  static const linkGreen = Color(0xFF10B981); // "Forgot password?" color

  // Divider
  static const dividerColor = Color(0xFFE5E7EB); // Divider line color

  // ---------- GRADIENTS ----------
  static const LinearGradient loginGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      gradientStart,
      gradientEnd,
    ],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      buttonGradientStart,
      buttonGradientEnd,
    ],
  );
}