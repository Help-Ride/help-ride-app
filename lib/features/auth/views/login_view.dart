import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:help_ride/core/constants/app_images.dart';
import '../../../core/constants/app_button.dart';
import '../../../core/constants/app_text_style.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/oauth_button.dart';

class LoginView extends GetView<AuthController> {
  LoginView({super.key}) {
    Get.put(AuthController(), permanent: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome',
                      style: AppTextStyles.h2(),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Sign in to continue',
                      style: AppTextStyles.subtitle(),
                    ),
                    SizedBox(height: 40),

                    // Email Address Label
                    Text(
                      'Email Address',
                      style: AppTextStyles.labelLarge(),
                    ),
                    SizedBox(height: 8),
                    AuthTextField(
                      hint: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      onChanged: controller.setEmail,
                    ),

                    SizedBox(height: 20),

                    // Password Label
                    Text(
                      'Password',
                      style: AppTextStyles.labelLarge(),
                    ),
                    SizedBox(height: 8),
                    AuthTextField(
                      hint: 'Enter your password',
                      obscureText: true,
                      onChanged: controller.setPassword,
                      suffixIcon: Icon(
                        Icons.visibility_outlined,
                        color: Colors.grey[400],
                      ),
                    ),

                    SizedBox(height: 12),

                    // Forgot Password Link
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {
                          // TODO: navigate to forgot password
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Forgot password?',
                          style: AppTextStyles.link(),
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Error Message
                    Obx(() {
                      final err = controller.error.value;
                      if (err == null) return SizedBox.shrink();
                      return Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          err,
                          style: AppTextStyles.error(),
                        ),
                      );
                    }),

                    // Sign In Button
                  Obx(() {
                    final emailLoading = controller.isLoading.value;

                    return GradientAppButton(
                      text: 'Sign In',
                      isLoading: emailLoading,
                      enabled: controller.canSubmit,
                      onPressed: controller.loginWithEmail,
                      prefixImage: AppImages.iconEmail, // optional
                    );
                  }),

                    SizedBox(height: 10),

                    // Use email verification code
                    Center(
                      child: TextButton(
                        onPressed: () {
                          // TODO: email verification flow
                        },
                        child: Text(
                          'Use email verification code instead',
                          style: AppTextStyles.bodyMedium(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 18),

                    // DIVIDER
                    Row(
                      children: [
                        Expanded(
                          child: Divider(thickness: 1, color: Colors.grey[300]),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Or continue with',
                            style: AppTextStyles.bodyMedium(
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(thickness: 1, color: Colors.grey[300]),
                        ),
                      ],
                    ),

                    SizedBox(height: 24),

                    // Google OAuth
                    Obx(() {
                      return OAuthButton(
                        icon: Icons.g_mobiledata,
                        iconSize: 28,
                        label: 'Continue with Google',
                        isLoading: controller.oauthLoading.value,
                        onPressed: controller.loginWithGoogle,
                      );
                    }),

                    SizedBox(height: 16),

                    // Apple OAuth
                    Obx(() {
                      return OAuthButton(
                        icon: Icons.apple,
                        iconSize: 24,
                        label: 'Continue with Apple',
                        isLoading: controller.oauthLoading.value,
                        onPressed: () {
                          // TODO: Apple login
                        },
                      );
                    }),

                    SizedBox(height: 24),

                    // Terms and Privacy
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'By continuing, you agree to our Terms of Service and Privacy Policy',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption(),
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