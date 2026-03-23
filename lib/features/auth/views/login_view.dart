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
      final titleColor = isDark ? AppColors.darkText : AppColors.lightText;
      final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;
      final dividerColor = isDark
          ? const Color(0xFF273041)
          : const Color(0xFFDCE3EF);

      return AuthScreenFrame(
        fillHeight: true,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BrandHeader(
                primary: primary,
                titleColor: titleColor,
                mutedColor: mutedColor,
                isDark: isDark,
              ),
              const SizedBox(height: 22),
              AuthPhoneField(
                controller: controller.phoneTextController,
                value: controller.phone.value,
                activeDialCode: controller.activeDialCodeOption,
                options: controller.dialCodeOptions,
                onChanged: controller.setPhone,
                onDialCodeChanged: controller.setDialCode,
                hint: '(416) 555-1234',
                errorText: controller.phone.value.trim().isEmpty
                    ? null
                    : controller.entryPhoneError,
                singleField: true,
                radius: 18,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
              ),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: controller.entryError.value != null
                    ? _FeedbackBanner(
                        key: const ValueKey('entry-error'),
                        message: controller.entryError.value!,
                        color: AppColors.error,
                        isDark: isDark,
                      )
                    : controller.entryMessage.value != null
                    ? _FeedbackBanner(
                        key: const ValueKey('entry-message'),
                        message: controller.entryMessage.value!,
                        color: primary,
                        isDark: isDark,
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: controller.canContinueWithPhone
                      ? controller.sendPhoneContinueOtp
                      : null,
                  style: _primaryButtonStyle(primary: primary, isDark: isDark),
                  child: controller.isSendingPhoneOtp.value
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Continue'),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'We’ll text you a one-time code',
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              _AuthDivider(
                label: 'or continue with',
                color: dividerColor,
                textColor: mutedColor,
              ),
              const SizedBox(height: 16),
              if (Platform.isIOS) ...[
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      apple_sign_in.SignInWithAppleButton(
                        onPressed: controller.canStartAppleOauth
                            ? controller.loginWithApple
                            : null,
                        text: 'Continue with Apple',
                        height: 56,
                        borderRadius: BorderRadius.circular(18),
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
                const SizedBox(height: 10),
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
                borderColor: dividerColor,
                backgroundColor: isDark
                    ? const Color(0xFF151B25)
                    : Colors.white,
                foregroundColor: socialForeground,
                isLoading: controller.googleOauthLoading.value,
                height: 56,
                radius: 18,
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => _showEmailSheet(context, primary, isDark),
                  style: TextButton.styleFrom(
                    foregroundColor: mutedColor,
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Use email instead'),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  'By continuing, you agree to our Terms of Service and Privacy Policy.',
                  style: TextStyle(
                    color: mutedColor,
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
      backgroundColor: isDark
          ? const Color(0xFF11161F)
          : Theme.of(context).colorScheme.surface,
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
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We will email you a 6-digit code to continue.',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkMuted
                          : AppColors.lightMuted,
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
                    height: 56,
                    child: ElevatedButton(
                      onPressed: controller.canContinueWithEmail
                          ? () async {
                              Navigator.of(sheetContext).pop();
                              await controller.sendEmailContinueOtp();
                            }
                          : null,
                      style: _primaryButtonStyle(
                        primary: primary,
                        isDark: isDark,
                      ),
                      child: controller.isSendingEmailOtp.value
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Continue'),
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

ButtonStyle _primaryButtonStyle({
  required Color primary,
  required bool isDark,
}) {
  final disabledBackground = Color.alphaBlend(
    primary.withValues(alpha: isDark ? 0.18 : 0.12),
    isDark ? const Color(0xFF111722) : const Color(0xFFF5F7FB),
  );
  final disabledForeground = isDark
      ? const Color(0xFFB8C1CF)
      : const Color(0xFF7A8599);

  return ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return disabledBackground;
      }
      return primary;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return disabledForeground;
      }
      return Colors.white;
    }),
    overlayColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.08)),
    elevation: WidgetStateProperty.all(0),
    padding: WidgetStateProperty.all(EdgeInsets.zero),
    textStyle: WidgetStateProperty.all(
      const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ),
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    side: WidgetStateProperty.resolveWith((states) {
      final color = states.contains(WidgetState.disabled)
          ? primary.withValues(alpha: isDark ? 0.18 : 0.12)
          : primary;
      return BorderSide(color: color);
    }),
  );
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({
    required this.primary,
    required this.titleColor,
    required this.mutedColor,
    required this.isDark,
  });

  final Color primary;
  final Color titleColor;
  final Color mutedColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HelpRide',
          style: TextStyle(
            color: mutedColor,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Get started',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            height: 1,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Book or offer rides in minutes',
          style: TextStyle(
            color: titleColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        _TrustPill(
          primary: primary,
          isDark: isDark,
          textColor: titleColor,
          label: 'Verified riders and drivers',
        ),
      ],
    );
  }
}

class _TrustPill extends StatelessWidget {
  const _TrustPill({
    required this.primary,
    required this.isDark,
    required this.textColor,
    required this.label,
  });

  final Color primary;
  final bool isDark;
  final Color textColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    final background = Color.alphaBlend(
      primary.withValues(alpha: isDark ? 0.18 : 0.1),
      isDark ? const Color(0xFF111722) : const Color(0xFFF7FAFD),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: primary.withValues(alpha: isDark ? 0.24 : 0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_outlined, size: 16, color: primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({
    super.key,
    required this.message,
    required this.color,
    required this.isDark,
  });

  final String message;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final background = Color.alphaBlend(
      color.withValues(alpha: isDark ? 0.16 : 0.08),
      isDark ? const Color(0xFF111722) : Colors.white,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      ),
    );
  }
}

class _AuthDivider extends StatelessWidget {
  const _AuthDivider({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: color, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Expanded(child: Divider(color: color, thickness: 1)),
      ],
    );
  }
}
