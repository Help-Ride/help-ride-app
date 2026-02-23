import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

InputDecoration appInputDecoration(
  BuildContext context, {
  String? hintText,
  String? labelText,
  Widget? prefixIcon,
  String? errorText,
  EdgeInsetsGeometry? contentPadding,
  double radius = 14,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final primary = Theme.of(context).colorScheme.primary;
  final borderColor = isDark
      ? const Color(0xFF2B3345)
      : const Color(0xFFDCE3EF);

  OutlineInputBorder border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    hintText: hintText,
    labelText: labelText,
    prefixIcon: prefixIcon,
    errorText: errorText,
    hintStyle: TextStyle(
      color: isDark ? AppColors.darkMuted : const Color(0xFF8B95A7),
      fontWeight: FontWeight.w500,
    ),
    labelStyle: TextStyle(
      color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
      fontWeight: FontWeight.w600,
    ),
    filled: true,
    fillColor: isDark ? const Color(0xFF1C2331) : const Color(0xFFF3F5F8),
    contentPadding:
        contentPadding ??
        const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    border: border(borderColor),
    enabledBorder: border(borderColor),
    focusedBorder: border(primary, width: 1.4),
    errorBorder: border(AppColors.error, width: 1.2),
    focusedErrorBorder: border(AppColors.error, width: 1.4),
  );
}
