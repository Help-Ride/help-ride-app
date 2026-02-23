import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_input_decoration.dart';

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
    this.errorText,
    this.inputFormatters,
    this.autofocus = false,
    this.maxLength,
  });

  final String label;
  final String hint;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;

  final TextEditingController? controller;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final String? errorText;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;
  final int? maxLength;

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
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          inputFormatters: inputFormatters,
          autofocus: autofocus,
          maxLength: maxLength,
          cursorColor: primary,
          decoration: appInputDecoration(
            context,
            hintText: hint,
            errorText: errorText,
            radius: 14,
          ).copyWith(counterText: maxLength == null ? null : ''),
        ),
      ],
    );
  }
}
