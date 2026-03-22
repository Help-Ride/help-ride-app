import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart' as apple_sign_in;
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_phone_field.dart';
import '../widgets/auth_screen_frame.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/social_auth_button.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<ThemeController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.isRegistered<AuthController>()) {
          controller.prepareEntryFromRouteArgs();
        }
      });

      final primary = theme.role.value == AppRole.driver
          ? AppColors.driverPrimary
          : AppColors.passengerPrimary;
      final socialForeground = isDark
          ? AppColors.darkText
          : AppColors.lightText;
      final sectionBg = isDark ? const Color(0xFF151B25) : Colors.white;
      final sectionBorder = isDark
          ? const Color(0xFF232836)
          : const Color(0xFFE1E6F0);
      return AuthScreenFrame(
        fillHeight: true,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Get started',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Enter your phone number to continue.',
                style: TextStyle(
                  color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                  fontSize: 18,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: sectionBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: sectionBorder),
                  boxShadow: isDark
                      ? null
                      : const [
                          BoxShadow(
                            blurRadius: 24,
                            offset: Offset(0, 16),
                            color: Color(0x120E1628),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AuthPhoneField(
                      controller: controller.phoneTextController,
                      value: controller.phone.value,
                      activeDialCode: controller.activeDialCodeOption,
                      options: controller.dialCodeOptions,
                      onChanged: controller.setPhone,
                      onDialCodeChanged: controller.setDialCode,
                      helperText:
                          'US and Canada numbers auto-format to +1. Use + country code for others.',
                      errorText: controller.phone.value.trim().isEmpty
                          ? null
                          : controller.entryPhoneError,
                      singleField: true,
                    ),
                    if (controller.entryMessage.value != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        controller.entryMessage.value!,
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (controller.entryError.value != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        controller.entryError.value!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: controller.canContinueWithPhone
                            ? controller.sendPhoneContinueOtp
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
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: controller.isSendingPhoneOtp.value
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'Continue',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: TextButton(
                  onPressed: () => _showEmailSheet(context, primary, isDark),
                  style: TextButton.styleFrom(foregroundColor: primary),
                  child: const Text('Use email instead'),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Other ways to continue',
                style: TextStyle(
                  color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 12),
              if (Platform.isIOS) ...[
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      apple_sign_in.SignInWithAppleButton(
                        onPressed: controller.canStartAppleOauth
                            ? controller.loginWithApple
                            : null,
                        text: 'Continue with Apple',
                        height: 54,
                        borderRadius: BorderRadius.circular(16),
                        style: isDark
                            ? apple_sign_in
                                  .SignInWithAppleButtonStyle
                                  .whiteOutlined
                            : apple_sign_in.SignInWithAppleButtonStyle.black,
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
              SocialAuthButton(
                label: 'Continue with Google',
                icon: const Text(
                  'G',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: Color(0xFF4285F4),
                  ),
                ),
                onPressed: controller.canStartGoogleOauth
                    ? controller.loginWithGoogle
                    : null,
                borderColor: isDark
                    ? const Color(0xFF232836)
                    : const Color(0xFFE2E6EF),
                backgroundColor: isDark ? const Color(0xFF151B25) : Colors.white,
                foregroundColor: socialForeground,
                isLoading: controller.googleOauthLoading.value,
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  'By continuing, you agree to our Terms of Service and Privacy Policy.',
                  style: TextStyle(
                    color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                    fontSize: 11,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _showEmailSheet(
    BuildContext context,
    Color primary,
    bool isDark,
  ) async {
    controller.clearEntryFeedback();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          isDark ? const Color(0xFF11161F) : Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            child: Obx(
              () => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Use email instead',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color:
                          isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We will email you a 6-digit code to continue.',
                    style: TextStyle(
                      color:
                          isDark ? AppColors.darkMuted : AppColors.lightMuted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 18),
                  AuthTextField(
                    label: 'Email address',
                    hint: 'you@example.com',
                    controller: controller.emailTextController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    onChanged: controller.setEmail,
                    errorText: controller.email.value.trim().isEmpty
                        ? null
                        : controller.entryEmailError,
                  ),
                  if (controller.entryError.value != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      controller.entryError.value!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (controller.entryMessage.value != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      controller.entryMessage.value!,
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: controller.canContinueWithEmail
                          ? () async {
                              Navigator.of(sheetContext).pop();
                              await controller.sendEmailContinueOtp();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: controller.isSendingEmailOtp.value
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Continue',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
