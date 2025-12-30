import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_text_field.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Login with your email to continue.',
                    style: TextStyle(color: AppColors.lightMuted),
                  ),
                  const SizedBox(height: 22),

                  AuthTextField(
                    label: 'Email',
                    hint: 'name@email.com',
                    keyboardType: TextInputType.emailAddress,
                    onChanged: controller.setEmail,
                  ),
                  const SizedBox(height: 12),
                  AuthTextField(
                    label: 'Password',
                    hint: '••••••••',
                    obscureText: true,
                    onChanged: controller.setPassword,
                  ),
                  const SizedBox(height: 14),

                  Obx(() {
                    final err = controller.error.value;
                    if (err == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        err,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    );
                  }),

                  // EMAIL LOGIN
                  Obx(() {
                    final emailLoading = controller.isLoading.value;
                    return SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (controller.canSubmit && !emailLoading)
                            ? controller.loginWithEmail
                            : null,
                        child: emailLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Login'),
                      ),
                    );
                  }),

                  const SizedBox(height: 18),

                  // DIVIDER
                  Row(
                    children: const [
                      Expanded(child: Divider(thickness: 1)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or',
                          style: TextStyle(color: AppColors.lightMuted),
                        ),
                      ),
                      Expanded(child: Divider(thickness: 1)),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // GOOGLE OAUTH
                  Obx(() {
                    final oauthLoading = controller.oauthLoading.value;
                    return SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: oauthLoading
                            ? null
                            : controller.loginWithGoogle,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE2E6EF)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: oauthLoading
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
                                  // Replace later with proper Google logo asset
                                  Icon(Icons.g_mobiledata, size: 28),
                                  SizedBox(width: 10),
                                  Text('Continue with Google'),
                                ],
                              ),
                      ),
                    );
                  }),

                  const SizedBox(height: 14),

                  TextButton(
                    onPressed: () {
                      // TODO: navigate to forgot password / reset
                    },
                    child: const Text('Forgot password?'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
