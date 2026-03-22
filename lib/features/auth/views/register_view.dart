import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_phone_field.dart';
import '../widgets/auth_screen_frame.dart';
import '../widgets/auth_text_field.dart';

class RegisterView extends GetView<AuthController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<ThemeController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.isRegistered<AuthController>()) {
          controller.prepareOnboardingFromRouteArgs();
        }
      });

      final primary = theme.role.value == AppRole.driver
          ? AppColors.driverPrimary
          : AppColors.passengerPrimary;

      return AuthScreenFrame(
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Complete your account',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                controller.onboardingHint.value ??
                    'Add a few details so we can finish setting up your account.',
                style: TextStyle(
                  color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                  fontSize: 16,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              if (controller.verifiedPhone != null)
                _VerifiedCard(
                  title: 'Phone verified',
                  value: controller.verifiedPhone!,
                  isDark: isDark,
                ),
              if (controller.verifiedEmail != null) ...[
                if (controller.verifiedPhone != null) const SizedBox(height: 12),
                _VerifiedCard(
                  title: 'Email verified',
                  value: controller.verifiedEmail!,
                  isDark: isDark,
                ),
              ],
              if (controller.verifiedPhone != null ||
                  controller.verifiedEmail != null)
                const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: AuthTextField(
                      label: 'First name',
                      hint: 'Rishi',
                      controller: controller.firstNameTextController,
                      onChanged: controller.setFirstName,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.givenName],
                      errorText: controller.firstName.value.trim().isEmpty
                          ? null
                          : controller.firstNameError,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AuthTextField(
                      label: 'Last name',
                      hint: 'Patel',
                      controller: controller.lastNameTextController,
                      onChanged: controller.setLastName,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.familyName],
                      errorText: controller.lastName.value.trim().isEmpty
                          ? null
                          : controller.lastNameError,
                    ),
                  ),
                ],
              ),
              if (controller.shouldShowOnboardingEmailField) ...[
                const SizedBox(height: 14),
                AuthTextField(
                  label: 'Email address (optional)',
                  hint: 'you@example.com',
                  controller: controller.onboardingEmailTextController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  onChanged: controller.setOnboardingEmail,
                  errorText: controller.onboardingEmail.value.trim().isEmpty
                      ? null
                      : controller.onboardingEmailError,
                ),
              ],
              if (controller.shouldShowOnboardingPhoneField) ...[
                const SizedBox(height: 14),
                AuthPhoneField(
                  controller: controller.onboardingPhoneTextController,
                  value: controller.onboardingPhone.value,
                  activeDialCode: controller.activeDialCodeOption,
                  options: controller.dialCodeOptions,
                  onChanged: controller.setOnboardingPhone,
                  onDialCodeChanged: controller.setDialCode,
                  label: 'Mobile number (optional)',
                  hint: '(416) 555-1234',
                  helperText:
                      'US and Canada numbers auto-format to +1. Use + country code for others.',
                  errorText: controller.onboardingPhone.value.trim().isEmpty
                      ? null
                      : controller.onboardingPhoneError,
                ),
              ],
              if (controller.onboardingError.value != null) ...[
                const SizedBox(height: 12),
                Text(
                  controller.onboardingError.value!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (controller.onboardingMessage.value != null) ...[
                const SizedBox(height: 12),
                Text(
                  controller.onboardingMessage.value!,
                  style: TextStyle(color: primary, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: controller.canCompleteOnboarding
                      ? controller.completeOnboarding
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
                  child: controller.isCompletingOnboarding.value
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Finish',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'You can update the rest later from your profile.',
                style: TextStyle(
                  color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _VerifiedCard extends StatelessWidget {
  const _VerifiedCard({
    required this.title,
    required this.value,
    required this.isDark,
  });

  final String title;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151B25) : const Color(0xFFF6F8FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3242) : const Color(0xFFDCE3EE),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
        ],
      ),
    );
  }
}
