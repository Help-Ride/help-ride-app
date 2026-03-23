import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

class OtpCodeField extends StatefulWidget {
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
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(covariant OtpCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autofocus &&
        !oldWidget.autofocus &&
        mounted &&
        !_focusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _requestFocus() {
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.passengerPrimary;
    final slots = List<String>.generate(
      6,
      (index) => index < widget.value.length ? widget.value[index] : '',
    );
    final activeIndex = widget.value.length.clamp(0, 5);

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
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _requestFocus,
          child: SizedBox(
            height: 62,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.02,
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      autofocus: widget.autofocus,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      cursorColor: Colors.transparent,
                      showCursor: false,
                      style: const TextStyle(
                        color: Colors.transparent,
                        fontSize: 1,
                        height: 1,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                      ),
                      maxLength: 6,
                      onChanged: widget.onChanged,
                    ),
                  ),
                ),
                IgnorePointer(
                  child: Row(
                    children: List.generate(6, (index) {
                      final char = slots[index];
                      final isActive =
                          _focusNode.hasFocus &&
                          (widget.value.isEmpty
                              ? index == 0
                              : (widget.value.length < 6
                                  ? index == activeIndex
                                  : index == 5));

                      return Expanded(
                        child: Container(
                          height: 62,
                          margin: EdgeInsets.only(right: index == 5 ? 0 : 8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF151B25)
                                : const Color(0xFFF6F8FC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              width: isActive ? 1.5 : 1,
                              color: char.isNotEmpty || isActive
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
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.errorText != null && widget.errorText!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            widget.errorText!,
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
