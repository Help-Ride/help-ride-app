import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_input_decoration.dart';

class ExoTextArea extends StatelessWidget {
  const ExoTextArea({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.errorText,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          minLines: 4,
          maxLines: 6,
          decoration: appInputDecoration(
            context,
            hintText: hint,
            errorText: errorText,
            radius: 16,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
