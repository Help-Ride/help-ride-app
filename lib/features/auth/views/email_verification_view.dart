import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../controllers/email_verification_controller.dart';
import '../widgets/auth_screen_frame.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_top_bar.dart';
import '../widgets/otp_code_field.dart';

class EmailVerificationView extends GetView<EmailVerificationController> {
  const EmailVerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<ThemeController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final primary = theme.role.value == AppRole.driver
          ? AppColors.driverPrimary
          : AppColors.passengerPrimary;

      return AuthScreenFrame(
        centerContent: controller.hasEmail,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuthTopBar(
                onBack: controller.goBack,
                onClose: controller.closeFlow,
              ),
              const SizedBox(height: 18),
              Text(
                controller.hasEmail ? 'Verify your email' : 'Add your email',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                controller.hasEmail
                    ? 'Enter the 6-digit code from your email.'
                    : 'Add your email first. We will send a 6-digit code before you can continue.',
                style: TextStyle(
                  color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                  fontSize: 16,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              if (!controller.hasEmail) ...[
                AuthTextField(
                  key: const ValueKey('email-verification-email'),
                  label: 'Email address',
                  hint: 'name@example.com',
                  controller: controller.emailTextController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  onChanged: controller.setEmail,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => controller.saveEmailAndSendOtp(),
                  errorText: controller.emailInput.value.trim().isEmpty
                      ? null
                      : controller.emailError,
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF101726)
                        : const Color(0xFFF5F7FB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF1C2331)
                          : const Color(0xFFD9E2EF),
                    ),
                  ),
                  child: Text(
                    controller.email,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OtpCodeField(
                  controller: controller.otpTextController,
                  value: controller.otp.value,
                  onChanged: controller.setOtp,
                  errorText: controller.otp.value.trim().isEmpty
                      ? null
                      : controller.otpError,
                ),
              ],
              const SizedBox(height: 12),
              Obx(() {
                final msg = controller.message.value;
                if (msg == null) return const SizedBox(height: 0);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    msg,
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }),
              Obx(() {
                final err = controller.error.value;
                if (err == null) return const SizedBox(height: 6);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    err,
                    style: const TextStyle(color: AppColors.error),
                  ),
                );
              }),
              Obx(() {
                final loading = controller.hasEmail
                    ? controller.isVerifying.value
                    : controller.isSavingEmail.value;
                final enabled = controller.hasEmail
                    ? (controller.canVerify && !loading)
                    : controller.canSubmitEmail;

                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: enabled
                        ? (controller.hasEmail
                              ? controller.verifyOtp
                              : controller.saveEmailAndSendOtp)
                        : null,
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
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            controller.hasEmail
                                ? 'Verify email'
                                : 'Email me a code',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                );
              }),
              const SizedBox(height: 10),
              if (controller.hasEmail)
                Center(
                  child: Obx(() {
                    final sending = controller.isSending.value;
                    return TextButton(
                      onPressed: sending ? null : controller.sendOtp,
                      style: TextButton.styleFrom(foregroundColor: primary),
                      child: sending
                          ? const Text('Sending...')
                          : const Text('Resend code'),
                    );
                  }),
                ),
              if (controller.allowBackToLogin)
                Center(
                  child: TextButton(
                    onPressed: controller.goBack,
                    style: TextButton.styleFrom(foregroundColor: primary),
                    child: const Text('Back to login'),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}
