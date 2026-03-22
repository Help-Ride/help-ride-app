import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

class OtpCodeField extends StatelessWidget {
  const OtpCodeField({
    super.key,
    required this.controller,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.autofocus = true,
  });

  final TextEditingController controller;
  final String value;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.passengerPrimary;
    final slots = List<String>.generate(
      6,
      (index) => index < value.length ? value[index] : '',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verification code',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
        const SizedBox(height: 10),
        Stack(
          children: [
            TextField(
              controller: controller,
              autofocus: autofocus,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              cursorColor: primary,
              style: const TextStyle(color: Colors.transparent, fontSize: 1),
              decoration: const InputDecoration(
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                counterText: '',
              ),
              maxLength: 6,
              onChanged: onChanged,
            ),
            IgnorePointer(
              child: Row(
                children: slots
                    .map(
                      (char) => Expanded(
                        child: Container(
                          height: 62,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF151B25)
                                : const Color(0xFFF6F8FC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: char.isNotEmpty
                                  ? primary
                                  : (isDark
                                      ? const Color(0xFF2A3242)
                                      : const Color(0xFFDCE3EE)),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            char,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkText
                                  : AppColors.lightText,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
        if (errorText != null && errorText!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            errorText!,
            style: const TextStyle(
              color: AppColors.error,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}
