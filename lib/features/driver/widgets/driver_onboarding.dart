import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:help_ride/features/driver/controllers/driver_onboarding_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/controllers/session_controller.dart';

class DriverOnboarding extends StatelessWidget {
  const DriverOnboarding({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(DriverOnboardingController(), permanent: false);
    final primary = AppColors.driverPrimary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Become a Driver',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'Add your vehicle info to start posting rides.',
                style: TextStyle(color: muted),
              ),

              const SizedBox(height: 18),

              Expanded(
                child: ListView(
                  children: [
                    _Field(
                      label: 'Car Make',
                      hint: 'Toyota',
                      onChanged: c.setCarMake,
                    ),
                    const SizedBox(height: 12),
                    _Field(
                      label: 'Car Model',
                      hint: 'Camry',
                      onChanged: c.setCarModel,
                    ),
                    const SizedBox(height: 12),
                    _Field(
                      label: 'Car Year',
                      hint: '2022',
                      keyboardType: TextInputType.number,
                      onChanged: c.setCarYear,
                    ),
                    const SizedBox(height: 12),
                    _Field(
                      label: 'Car Color',
                      hint: 'Silver',
                      onChanged: c.setCarColor,
                    ),
                    const SizedBox(height: 12),
                    _Field(
                      label: 'Plate Number',
                      hint: 'ABC-1234',
                      onChanged: c.setPlateNumber,
                    ),
                    const SizedBox(height: 12),
                    _Field(
                      label: 'License Number',
                      hint: 'LIC-987654',
                      onChanged: c.setLicenseNumber,
                    ),
                    const SizedBox(height: 12),
                    _Field(
                      label: 'Insurance Info (optional)',
                      hint: 'Provider / policy',
                      onChanged: c.setInsuranceInfo,
                    ),

                    const SizedBox(height: 14),

                    Obx(() {
                      final err = c.error.value;
                      if (err == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          err,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      );
                    }),

                    Obx(() {
                      final loading = c.loading.value;
                      return SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: loading
                              ? null
                              : () async {
                                  await c.submit();

                                  // refresh session so driverProfile appears
                                  final session = Get.find<SessionController>();
                                  await session.bootstrap();

                                  // DriverHomeGate will switch automatically
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                isDark ? const Color(0xFF1C2331) : const Color(0xFFE9EEF6),
                            disabledForegroundColor:
                                isDark ? AppColors.darkMuted : const Color(0xFF9AA3B2),
                            elevation: 0,
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
                              : const Text(
                                  'Save & Continue',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                        ),
                      );
                    }),

                    const SizedBox(height: 10),
                    Text(
                      'Note: Verification may be required later.',
                      style: TextStyle(
                        color: muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.hint,
    required this.onChanged,
    this.keyboardType,
  });

  final String label;
  final String hint;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: isDark ? const Color(0xFF1C2331) : const Color(0xFFF3F5F8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
