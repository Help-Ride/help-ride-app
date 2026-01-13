import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/driver_onboarding_controller.dart';

class DriverOnboardingView extends GetView<DriverOnboardingController> {
  const DriverOnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.driverPrimary;

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.lightBg,
        elevation: 0,
        title: const Text(
          'Become a Driver',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: ListView(
            children: [
              _Field(
                label: 'Car Make',
                hint: 'Toyota',
                onChanged: controller.setCarMake,
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Car Model',
                hint: 'Camry',
                onChanged: controller.setCarModel,
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Car Year',
                hint: '2022',
                keyboardType: TextInputType.number,
                onChanged: controller.setCarYear,
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Car Color',
                hint: 'Silver',
                onChanged: controller.setCarColor,
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Plate Number',
                hint: 'ABC-1234',
                onChanged: controller.setPlateNumber,
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'License Number',
                hint: 'LIC-987654',
                onChanged: controller.setLicenseNumber,
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Insurance Info (optional)',
                hint: 'Provider / policy',
                onChanged: controller.setInsuranceInfo,
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
                final loading = controller.loading.value;
                return SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: loading ? null : controller.submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Save & Continue',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                  ),
                );
              }),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        TextField(
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF3F5F8),
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
