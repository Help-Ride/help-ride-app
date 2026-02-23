import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../controllers/password_reset_controller.dart';
import '../routes/auth_routes.dart';
import '../widgets/auth_text_field.dart';

class PasswordResetView extends GetView<PasswordResetController> {
  const PasswordResetView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<ThemeController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final surface = Theme.of(context).colorScheme.surface;

    return Obx(() {
      final primary = theme.role.value == AppRole.driver
          ? AppColors.driverPrimary
          : AppColors.passengerPrimary;

      return Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF232836)
                          : const Color(0xFFE6EAF2),
                    ),
                    boxShadow: isDark
                        ? []
                        : const [
                            BoxShadow(
                              blurRadius: 30,
                              offset: Offset(0, 18),
                              color: Color(0x14000000),
                            ),
                          ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reset password',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.darkText
                              : AppColors.lightText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        controller.otpSent.value
                            ? 'Enter the code from your email and choose a new password.'
                            : 'Enter your email and we will send a 6-digit code.',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkMuted
                              : AppColors.lightMuted,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 22),
                      AuthTextField(
                        label: 'Email Address',
                        hint: 'you@example.com',
                        keyboardType: TextInputType.emailAddress,
                        onChanged: controller.setEmail,
                        textInputAction: controller.otpSent.value
                            ? TextInputAction.next
                            : TextInputAction.done,
                        onSubmitted: (_) {
                          if (!controller.otpSent.value) {
                            controller.sendOtp();
                          }
                        },
                        errorText: controller.email.value.trim().isEmpty
                            ? null
                            : controller.emailError,
                      ),
                      if (controller.otpSent.value) ...[
                        const SizedBox(height: 14),
                        AuthTextField(
                          label: 'Verification code',
                          hint: 'Enter 6-digit code',
                          keyboardType: TextInputType.number,
                          onChanged: controller.setOtp,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          maxLength: 6,
                          errorText: controller.otp.value.trim().isEmpty
                              ? null
                              : controller.otpError,
                        ),
                        const SizedBox(height: 14),
                        AuthTextField(
                          label: 'New password',
                          hint: 'Min 8 characters',
                          obscureText: true,
                          onChanged: controller.setNewPassword,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => controller.resetPassword(),
                          errorText: controller.newPassword.value.trim().isEmpty
                              ? null
                              : controller.newPasswordError,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Obx(() {
                        final msg = controller.message.value;
                        if (msg == null) return const SizedBox(height: 0);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(msg, style: TextStyle(color: primary)),
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
                      if (!controller.otpSent.value)
                        Obx(() {
                          final loading = controller.isSendingOtp.value;
                          final enabled = controller.canSendOtp && !loading;

                          return SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: enabled ? controller.sendOtp : null,
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
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Send Code',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          );
                        }),
                      if (controller.otpSent.value) ...[
                        Obx(() {
                          final loading = controller.isResetting.value;
                          final enabled =
                              controller.canResetPassword && !loading;

                          return SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: enabled
                                  ? controller.resetPassword
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
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Reset Password',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        Obx(() {
                          final sending = controller.isSendingOtp.value;
                          return Center(
                            child: TextButton(
                              onPressed: sending ? null : controller.sendOtp,
                              child: sending
                                  ? const Text('Sending...')
                                  : const Text('Resend code'),
                            ),
                          );
                        }),
                      ],
                      Center(
                        child: TextButton(
                          onPressed: () => Get.offAllNamed(AuthRoutes.login),
                          child: const Text('Back to login'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
