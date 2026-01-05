import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_text_field.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.lightBg;
    final surface = AppColors.lightSurface;
    final primary = AppColors.passengerPrimary;

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
                  boxShadow: const [
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
                    const Text(
                      "Welcome",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Sign in to continue",
                      style: TextStyle(
                        color: AppColors.lightMuted,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 22),

                    AuthTextField(
                      label: 'Email Address',
                      hint: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      onChanged: controller.setEmail,
                    ),
                    const SizedBox(height: 14),
                    AuthTextField(
                      label: 'Password',
                      hint: 'Enter your password',
                      obscureText: true,
                      onChanged: controller.setPassword,
                    ),

                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: primary,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(10, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          // TODO: forgot password
                        },
                        child: const Text("Forgot password?"),
                      ),
                    ),

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
                      final enabled = controller.canSubmit && !loading;

                      return SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: enabled ? controller.loginWithEmail : null,
                          icon: const Icon(Icons.mail_outline, size: 18),
                          label: loading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text("Sign In"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFE9EEF6),
                            disabledForegroundColor: const Color(0xFF9AA3B2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 16),

                    Row(
                      children: const [
                        Expanded(child: Divider(height: 1)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            "Or continue with",
                            style: TextStyle(
                              color: AppColors.lightMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(height: 1)),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Obx(() {
                      final loading = controller.oauthLoading.value;
                      return SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: loading
                              ? null
                              : controller.loginWithGoogle,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE2E6EF)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: loading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Text(
                                      "G",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      "Continue with Google",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    }),

                    const SizedBox(height: 14),
                    const Text(
                      "By continuing, you agree to our Terms of Service and Privacy Policy",
                      style: TextStyle(
                        color: AppColors.lightMuted,
                        fontSize: 11,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Center(
                      child: TextButton(
                        onPressed: () => Get.toNamed('/register'),
                        child: Text(
                          "Don’t have an account? Create one",
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
  }
}
