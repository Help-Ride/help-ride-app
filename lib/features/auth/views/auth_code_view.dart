import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../controllers/auth_code_controller.dart';
import '../widgets/auth_screen_frame.dart';
import '../widgets/otp_code_field.dart';

class AuthCodeView extends GetView<AuthCodeController> {
  const AuthCodeView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<ThemeController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final primary = theme.role.value == AppRole.driver
          ? AppColors.driverPrimary
          : AppColors.passengerPrimary;

      return AuthScreenFrame(
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: controller.wrongDestination,
                style: TextButton.styleFrom(
                  foregroundColor: isDark
                      ? AppColors.darkMuted
                      : AppColors.lightMuted,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(10, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Back'),
              ),
              const SizedBox(height: 14),
              Text(
                controller.title,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                controller.subtitle,
                style: TextStyle(
                  color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                  fontSize: 16,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              OtpCodeField(
                controller: controller.otpTextController,
                value: controller.otp.value,
                onChanged: controller.setOtp,
                errorText: controller.otp.value.trim().isEmpty
                    ? null
                    : controller.otpError,
              ),
              if (controller.message.value != null) ...[
                const SizedBox(height: 12),
                Text(
                  controller.message.value!,
                  style: TextStyle(color: primary, fontWeight: FontWeight.w600),
                ),
              ],
              if (controller.error.value != null) ...[
                const SizedBox(height: 12),
                Text(
                  controller.error.value!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: controller.canVerify ? controller.verifyOtp : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: isDark
                        ? const Color(0xFF1C2331)
                        : const Color(0xFFE9EEF6),
                    disabledForegroundColor: isDark
                        ? AppColors.darkMuted
                        : const Color(0xFF9AA3B2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: controller.isVerifying.value
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: controller.canResend ? controller.resendCode : null,
                  child: controller.isSending.value
                      ? const Text('Sending...')
                      : Text(
                          controller.resendRemainingSeconds.value == 0
                              ? 'Resend code'
                              : 'Resend in ${controller.resendRemainingSeconds.value}s',
                        ),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: controller.wrongDestination,
                  child: Text(controller.wrongDestinationLabel),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
