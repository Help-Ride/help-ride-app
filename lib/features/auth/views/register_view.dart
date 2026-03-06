import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../shared/utils/phone_number_utils.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_text_field.dart';

class RegisterView extends GetView<AuthController> {
  const RegisterView({super.key});

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
                        'Create account',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.darkText
                              : AppColors.lightText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'We will verify your mobile number before your account goes live.',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkMuted
                              : AppColors.lightMuted,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 22),
                      AuthTextField(
                        label: 'Full Name',
                        hint: 'Rishhi Patel',
                        onChanged: controller.setName,
                        textInputAction: TextInputAction.next,
                        errorText: controller.name.value.trim().isEmpty
                            ? null
                            : controller.nameError,
                      ),
                      const SizedBox(height: 14),
                      AuthTextField(
                        label: 'Mobile Number',
                        hint: '(416) 555-1234',
                        keyboardType: TextInputType.phone,
                        onChanged: controller.setPhone,
                        textInputAction: TextInputAction.next,
                        inputFormatters: const [PhoneTextInputFormatter()],
                        helperText:
                            'Required for ride alerts, OTP sign-in, and SMS updates when a new ride is available.',
                        errorText: controller.phone.value.trim().isEmpty
                            ? null
                            : controller.registerPhoneError,
                      ),
                      const SizedBox(height: 14),
                      AuthTextField(
                        label: 'Email Address',
                        hint: 'you@example.com',
                        keyboardType: TextInputType.emailAddress,
                        onChanged: controller.setEmail,
                        textInputAction: TextInputAction.next,
                        errorText: controller.email.value.trim().isEmpty
                            ? null
                            : controller.emailError,
                      ),
                      const SizedBox(height: 14),
                      AuthTextField(
                        label: 'Password',
                        hint: 'Min 8 characters',
                        obscureText: true,
                        onChanged: controller.setPassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => controller.registerWithEmail(),
                        errorText: controller.password.value.trim().isEmpty
                            ? null
                            : controller.passwordError,
                      ),
                      const SizedBox(height: 10),
                      if (controller.error.value != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            controller.error.value!,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed:
                              controller.canRegister &&
                                  !controller.isLoading.value
                              ? controller.registerWithEmail
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
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Create Account',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'We will text a verification code right after signup. US/Canada numbers auto-normalize to +1.',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkMuted
                              : AppColors.lightMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: TextButton(
                          onPressed: () => Get.back(),
                          child: Text(
                            'Already have an account? Sign in',
                            style: TextStyle(color: primary),
                          ),
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
