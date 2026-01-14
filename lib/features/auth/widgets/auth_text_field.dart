import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    this.controller,
    this.textInputAction,
    this.onSubmitted,
  });

  final String label;
  final String hint;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;

  final TextEditingController? controller;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.passengerPrimary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          onChanged: onChanged,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          cursorColor: primary,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? AppColors.darkMuted : const Color(0xFF9AA3B2),
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1C2331) : const Color(0xFFF3F5F8),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primary, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}
