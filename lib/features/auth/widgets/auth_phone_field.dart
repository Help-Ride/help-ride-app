import 'package:flutter/material.dart';
import 'package:help_ride/features/auth/models/dial_code_option.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/utils/phone_number_utils.dart';
import '../../../shared/widgets/app_input_decoration.dart';

class AuthPhoneField extends StatelessWidget {
  const AuthPhoneField({
    super.key,
    required this.controller,
    required this.value,
    required this.activeDialCode,
    required this.options,
    required this.onChanged,
    required this.onDialCodeChanged,
    this.label = 'Phone number',
    this.hint = '(416) 555-1234',
    this.errorText,
    this.helperText,
    this.singleField = false,
    this.radius = 14,
    this.contentPadding,
  });

  final TextEditingController controller;
  final String value;
  final DialCodeOption activeDialCode;
  final List<DialCodeOption> options;
  final ValueChanged<String> onChanged;
  final ValueChanged<DialCodeOption> onDialCodeChanged;
  final String label;
  final String hint;
  final String? errorText;
  final String? helperText;
  final bool singleField;
  final double radius;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
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
        _buildTextField(context),
        if ((helperText?.trim().isNotEmpty ?? false) ||
            (errorText?.trim().isNotEmpty ?? false)) ...[
          const SizedBox(height: 8),
          Text(
            errorText?.trim().isNotEmpty == true ? errorText! : helperText!,
            style: TextStyle(
              color: errorText?.trim().isNotEmpty == true
                  ? AppColors.error
                  : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.phone,
      autofillHints: const [AutofillHints.telephoneNumber],
      textInputAction: TextInputAction.done,
      autocorrect: false,
      enableSuggestions: false,
      onChanged: onChanged,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      inputFormatters: const [PhoneTextInputFormatter()],
      cursorColor: AppColors.passengerPrimary,
      decoration:
          appInputDecoration(
            context,
            hintText: hint,
            radius: radius,
            contentPadding: contentPadding,
          ).copyWith(
            errorText: errorText == null ? null : ' ',
            errorStyle: const TextStyle(fontSize: 0, height: 0),
          ),
    );
  }
}
