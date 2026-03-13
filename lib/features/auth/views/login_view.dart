import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart' as apple_sign_in;
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../controllers/auth_controller.dart';
import '../routes/auth_routes.dart';
import '../widgets/auth_text_field.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

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
                        'Welcome',
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
                        controller.isOtpLogin
                            ? 'Use a one-time code from email or SMS.'
                            : 'Sign in to continue.',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkMuted
                              : AppColors.lightMuted,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _SegmentRow<AuthLoginMethod>(
                        selected: controller.loginMethod.value,
                        onChanged: controller.selectLoginMethod,
                        primary: primary,
                        isDark: isDark,
                        items: const {
                          AuthLoginMethod.password: 'Password',
                          AuthLoginMethod.otp: 'One-Time Code',
                        },
                      ),
                      const SizedBox(height: 18),
                      if (!controller.isOtpLogin) ...[
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
                          hint: 'Enter your password',
                          obscureText: true,
                          onChanged: controller.setPassword,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => controller.loginWithEmail(),
                          errorText: controller.password.value.trim().isEmpty
                              ? null
                              : controller.passwordError,
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
                              Get.toNamed(AuthRoutes.passwordReset);
                            },
                            child: const Text('Forgot password?'),
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Enter your email address or mobile number and we will send a 6-digit sign-in code.',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkMuted
                                : AppColors.lightMuted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 14),
                        AuthTextField(
                          label: 'Email or Mobile Number',
                          hint: 'you@example.com or +1 416 555 1234',
                          keyboardType: TextInputType.text,
                          onChanged: controller.setOtpIdentifier,
                          textInputAction: controller.otpSent.value
                              ? TextInputAction.next
                              : TextInputAction.done,
                          onSubmitted: (_) {
                            if (!controller.otpSent.value) {
                              controller.sendLoginOtp();
                            }
                          },
                          helperText: controller.isOtpPhoneInput
                              ? 'We will send the code by SMS.'
                              : controller.isOtpEmailInput
                              ? 'We will send the code by email.'
                              : 'Phone numbers auto-normalize to +1 for US/Canada.',
                          errorText:
                              controller.otpIdentifier.value.trim().isEmpty
                              ? null
                              : controller.otpIdentifierError,
                        ),
                        if (controller.otpSent.value) ...[
                          const SizedBox(height: 14),
                          AuthTextField(
                            label: 'Verification Code',
                            hint: 'Enter 6-digit code',
                            keyboardType: TextInputType.number,
                            onChanged: controller.setLoginOtp,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => controller.verifyLoginOtp(),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            maxLength: 6,
                            errorText: controller.loginOtp.value.trim().isEmpty
                                ? null
                                : controller.loginOtpError,
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: TextButton(
                              onPressed: controller.isSendingOtp.value
                                  ? null
                                  : controller.sendLoginOtp,
                              child: controller.isSendingOtp.value
                                  ? const Text('Sending...')
                                  : const Text('Resend code'),
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 4),
                      if (controller.message.value != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            controller.message.value!,
                            style: TextStyle(color: primary),
                          ),
                        ),
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
                        child: ElevatedButton.icon(
                          onPressed: _primaryActionEnabled(controller)
                              ? () {
                                  if (!controller.isOtpLogin) {
                                    controller.loginWithEmail();
                                  } else if (controller.otpSent.value) {
                                    controller.verifyLoginOtp();
                                  } else {
                                    controller.sendLoginOtp();
                                  }
                                }
                              : null,
                          icon: _primaryActionIcon(controller),
                          label: _primaryActionLabel(controller),
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
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(child: Divider(height: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'Or continue with',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.darkMuted
                                    : AppColors.lightMuted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider(height: 1)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (Platform.isIOS) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              apple_sign_in.SignInWithAppleButton(
                                onPressed: controller.canStartAppleOauth
                                    ? controller.loginWithApple
                                    : null,
                                height: 52,
                                borderRadius: BorderRadius.circular(14),
                                style: isDark
                                    ? apple_sign_in
                                          .SignInWithAppleButtonStyle
                                          .whiteOutlined
                                    : apple_sign_in
                                          .SignInWithAppleButtonStyle
                                          .black,
                                iconAlignment: apple_sign_in.IconAlignment.left,
                              ),
                              if (controller.appleOauthLoading.value)
                                SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isDark ? Colors.black : Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: controller.canStartGoogleOauth
                              ? controller.loginWithGoogle
                              : null,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF232836)
                                  : const Color(0xFFE2E6EF),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: controller.googleOauthLoading.value
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
                                      'G',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Continue with Google',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'By continuing, you agree to our Terms of Service and Privacy Policy.',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkMuted
                              : AppColors.lightMuted,
                          fontSize: 11,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Center(
                        child: TextButton(
                          onPressed: () => Get.toNamed(AuthRoutes.register),
                          child: Text(
                            'Don’t have an account? Create one',
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

  bool _primaryActionEnabled(AuthController controller) {
    if (!controller.isOtpLogin) {
      return controller.canSubmit && !controller.isLoading.value;
    }

    if (controller.otpSent.value) {
      return controller.canVerifyLoginOtp && !controller.isVerifyingOtp.value;
    }

    return controller.canSendLoginOtp && !controller.isSendingOtp.value;
  }

  Widget _primaryActionIcon(AuthController controller) {
    if (!controller.isOtpLogin) {
      if (controller.isLoading.value) {
        return const SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      }
      return const Icon(Icons.mail_outline, size: 18);
    }

    if (controller.otpSent.value) {
      if (controller.isVerifyingOtp.value) {
        return const SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      }
      return const Icon(Icons.verified_outlined, size: 18);
    }

    if (controller.isSendingOtp.value) {
      return const SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Icon(
      controller.isOtpPhoneInput
          ? Icons.sms_outlined
          : controller.isOtpEmailInput
          ? Icons.mark_email_read_outlined
          : Icons.send_outlined,
      size: 18,
    );
  }

  Widget _primaryActionLabel(AuthController controller) {
    if (!controller.isOtpLogin) {
      return controller.isLoading.value
          ? const SizedBox.shrink()
          : const Text('Sign In');
    }

    if (controller.otpSent.value) {
      return controller.isVerifyingOtp.value
          ? const SizedBox.shrink()
          : const Text('Verify & Sign In');
    }

    return controller.isSendingOtp.value
        ? const SizedBox.shrink()
        : Text(
            controller.isOtpPhoneInput
                ? 'Text Me a Code'
                : controller.isOtpEmailInput
                ? 'Email Me a Code'
                : 'Send Me a Code',
          );
  }
}

class _SegmentRow<T> extends StatelessWidget {
  const _SegmentRow({
    required this.selected,
    required this.onChanged,
    required this.primary,
    required this.isDark,
    required this.items,
  });

  final T selected;
  final ValueChanged<T> onChanged;
  final Color primary;
  final bool isDark;
  final Map<T, String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121826) : const Color(0xFFF3F5F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF232836) : const Color(0xFFE3E7EF),
        ),
      ),
      child: Row(
        children: items.entries.map((entry) {
          final active = entry.key == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: active
                      ? (isDark ? const Color(0xFF1C2331) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: active && !isDark
                      ? const [
                          BoxShadow(
                            blurRadius: 12,
                            offset: Offset(0, 6),
                            color: Color(0x10000000),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  entry.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: active
                        ? primary
                        : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
