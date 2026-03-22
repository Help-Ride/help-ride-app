import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
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
    this.hint = '415 555 1234',
    this.errorText,
    this.helperText,
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
        Row(
          children: [
            SizedBox(
              width: 104,
              child: OutlinedButton(
                onPressed: () => _showDialCodeSheet(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 17,
                  ),
                  backgroundColor: isDark
                      ? const Color(0xFF151B25)
                      : const Color(0xFFF6F8FC),
                  foregroundColor: isDark
                      ? AppColors.darkText
                      : AppColors.lightText,
                  side: BorderSide(
                    color: isDark
                        ? const Color(0xFF2A3242)
                        : const Color(0xFFDCE3EE),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        activeDialCode.dialCode,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.expand_more_rounded, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                textInputAction: TextInputAction.done,
                autocorrect: false,
                enableSuggestions: false,
                onChanged: onChanged,
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                inputFormatters: activeDialCode.dialCode == '+1'
                    ? const [PhoneTextInputFormatter()]
                    : [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]'))],
                cursorColor: AppColors.passengerPrimary,
                decoration: appInputDecoration(
                  context,
                  hintText: hint,
                  errorText: errorText,
                  helperText: helperText,
                  helperMaxLines: 2,
                  radius: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showDialCodeSheet(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          isDark ? const Color(0xFF11161F) : Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose country code',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 12),
                for (final option in options)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(option.countryName),
                    subtitle: Text(option.dialCode),
                    trailing: option.dialCode == activeDialCode.dialCode
                        ? const Icon(Icons.check_rounded)
                        : null,
                    onTap: () {
                      onDialCodeChanged(option);
                      Get.back<void>();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
