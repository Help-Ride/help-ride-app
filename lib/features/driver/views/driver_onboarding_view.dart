import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:help_ride/features/home/controllers/home_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/driver_onboarding_controller.dart';

class DriverOnboardingView extends StatefulWidget {
  const DriverOnboardingView({super.key});

  @override
  State<DriverOnboardingView> createState() => _DriverOnboardingViewState();
}

class _DriverOnboardingViewState extends State<DriverOnboardingView>
    with SingleTickerProviderStateMixin {
  bool showForm = false;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.driverPrimary;

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.lightBg,
        elevation: 0,
        foregroundColor: AppColors.lightText,
        title: const Text(
          'Become a Driver',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) {
              final slide = Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(anim);
              return FadeTransition(
                opacity: anim,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: showForm
                ? _DriverForm(
                    key: const ValueKey('form'),
                    primary: primary,
                    onBackToCta: () => setState(() => showForm = false),
                  )
                : _DriverCta(
                    key: const ValueKey('cta'),
                    primary: primary,
                    onStart: () => setState(() => showForm = true),
                  ),
          ),
        ),
      ),
    );
  }
}

class _DriverCta extends StatelessWidget {
  const _DriverCta({super.key, required this.primary, required this.onStart});

  final Color primary;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          "Start earning by offering rides",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        const Text(
          "Add your vehicle details. Takes less than a minute.",
          style: TextStyle(color: AppColors.lightMuted, height: 1.4),
        ),
        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE6EAF2)),
            boxShadow: const [
              BoxShadow(
                blurRadius: 22,
                offset: Offset(0, 14),
                color: Color(0x12000000),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _BenefitRow(
                icon: Icons.verified_user_outlined,
                text: "Verified driver profile",
              ),
              SizedBox(height: 10),
              _BenefitRow(
                icon: Icons.payments_outlined,
                text: "Track earnings & requests",
              ),
              SizedBox(height: 10),
              _BenefitRow(
                icon: Icons.route_outlined,
                text: "Post rides in seconds",
              ),
            ],
          ),
        ),

        const Spacer(),

        SizedBox(
          height: 52,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onStart,
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              "Become a Driver",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              Get.find<HomeController>().setRole(HomeRole.passenger);
              Get.offAllNamed('/home');
            },
            child: Text('Not now', style: TextStyle(color: primary)),
          ),
        ),
      ],
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.lightMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class ExoField extends StatelessWidget {
  const ExoField({
    super.key,
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _DriverForm extends GetView<DriverOnboardingController> {
  const _DriverForm({
    super.key,
    required this.primary,
    required this.onBackToCta,
  });

  final Color primary;
  final VoidCallback onBackToCta;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              ExoField(
                label: 'Car Make',
                hint: 'Toyota',
                onChanged: controller.setCarMake,
              ),
              const SizedBox(height: 12),
              ExoField(
                label: 'Car Model',
                hint: 'Camry',
                onChanged: controller.setCarModel,
              ),
              const SizedBox(height: 12),
              ExoField(
                label: 'Car Year',
                hint: '2022',
                keyboardType: TextInputType.number,
                onChanged: controller.setCarYear,
              ),
              const SizedBox(height: 12),
              ExoField(
                label: 'Car Color',
                hint: 'Silver',
                onChanged: controller.setCarColor,
              ),
              const SizedBox(height: 12),
              ExoField(
                label: 'Plate Number',
                hint: 'ABC-1234',
                onChanged: controller.setPlateNumber,
              ),
              const SizedBox(height: 12),
              ExoField(
                label: 'License Number',
                hint: 'LIC-987654',
                onChanged: controller.setLicenseNumber,
              ),
              const SizedBox(height: 12),
              ExoField(
                label: 'Insurance Info (optional)',
                hint: 'Provider / policy',
                onChanged: controller.setInsuranceInfo,
              ),

              const SizedBox(height: 14),

              Obx(() {
                final err = controller.error.value;
                if (err == null) return const SizedBox.shrink();
                return Text(
                  err,
                  style: const TextStyle(color: AppColors.error),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onBackToCta,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: BorderSide(color: primary),
                ),
                child: Text('Back', style: TextStyle(color: primary)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Obx(() {
                final loading = controller.loading.value;
                return ElevatedButton(
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
                );
              }),
            ),
          ],
        ),
      ],
    );
  }
}
