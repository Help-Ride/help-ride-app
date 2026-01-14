import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../routes/auth_routes.dart';
import '../controllers/email_verification_controller.dart';
import '../widgets/auth_text_field.dart';

class EmailVerificationView extends GetView<EmailVerificationController> {
  const EmailVerificationView({super.key});

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
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color:
                          isDark ? const Color(0xFF232836) : const Color(0xFFE6EAF2),
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
                        'Verify your email',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We sent a 6-digit code to ${controller.email}.',
                        style: TextStyle(
                          color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 22),
                      AuthTextField(
                        label: 'Verification code',
                        hint: 'Enter 6-digit code',
                        keyboardType: TextInputType.number,
                        onChanged: controller.setOtp,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => controller.verifyOtp(),
                      ),
                      const SizedBox(height: 12),
                      Obx(() {
                        final msg = controller.message.value;
                        if (msg == null) return const SizedBox(height: 0);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            msg,
                            style: TextStyle(color: primary),
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
                        final loading = controller.isVerifying.value;
                        final enabled = controller.canVerify && !loading;

                        return SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed:
                                enabled ? controller.verifyOtp : null,
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
                                    'Verify Email',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700),
                                  ),
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                      Obx(() {
                        final sending = controller.isSending.value;
                        return Center(
                          child: TextButton(
                            onPressed:
                                sending ? null : controller.sendOtp,
                            child: sending
                                ? const Text('Sending...')
                                : const Text('Resend code'),
                          ),
                        );
                      }),
                      Center(
                        child: TextButton(
                          onPressed: () =>
                              Get.offAllNamed(AuthRoutes.login),
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
