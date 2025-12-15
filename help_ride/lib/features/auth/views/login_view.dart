import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_text_field.dart';

class LoginView extends GetView<AuthController> {
  LoginView({super.key}) {
    Get.put(AuthController());
  }

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

                  Obx(() {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.canSubmit
                            ? controller.loginWithEmail
                            : null,
                        child: controller.isLoading.value
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

                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () {
                      // TODO: navigate to register/forgot password
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
