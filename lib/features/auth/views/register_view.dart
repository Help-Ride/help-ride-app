import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/constants/app_constants.dart';
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
                        "Create account",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Sign up to get started",
                        style: TextStyle(
                          color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 22),

                    // optional name
                    AuthTextField(
                      label: 'Full Name (optional)',
                      hint: 'Rishhi Patel',
                      onChanged: controller.setName,
                    ),
                    const SizedBox(height: 14),

                    AuthTextField(
                      label: 'Email Address',
                      hint: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      onChanged: controller.setEmail,
                    ),
                    const SizedBox(height: 14),

                    AuthTextField(
                      label: 'Password',
                      hint: 'Min 6 characters',
                      obscureText: true,
                      onChanged: controller.setPassword,
                    ),

                    const SizedBox(height: 10),

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
                      final loading = controller.isLoading.value;
                      final enabled = controller.canRegister && !loading;

                      return SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: enabled
                              ? controller.registerWithEmail
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                isDark ? const Color(0xFF1C2331) : const Color(0xFFE9EEF6),
                            disabledForegroundColor:
                                isDark ? AppColors.darkMuted : const Color(0xFF9AA3B2),
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
                                  "Create Account",
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                        ),
                      );
                    }),

                    const SizedBox(height: 14),

                      Center(
                        child: TextButton(
                          onPressed: () => Get.back(),
                          child: Text(
                            "Already have an account? Sign in",
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
