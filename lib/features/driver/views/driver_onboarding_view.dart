import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:help_ride/features/home/controllers/home_controller.dart';
import 'package:help_ride/core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_input_decoration.dart';
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
  void initState() {
    super.initState();
    if (!Get.isRegistered<DriverOnboardingController>()) {
      Get.lazyPut<DriverOnboardingController>(
        () => DriverOnboardingController(),
        fenix: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.driverPrimary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: isDark ? AppColors.darkText : AppColors.lightText,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          "Start earning by offering rides",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Add your vehicle details. Takes less than a minute.",
          style: TextStyle(color: muted, height: 1.4),
        ),
        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? const Color(0xFF232836) : const Color(0xFFE6EAF2),
            ),
            boxShadow: isDark
                ? []
                : const [
                    BoxShadow(
                      blurRadius: 22,
                      offset: Offset(0, 14),
                      color: Color(0x12000000),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BenefitRow(
                icon: Icons.verified_user_outlined,
                text: "Verified driver profile",
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _BenefitRow(
                icon: Icons.payments_outlined,
                text: "Track earnings & requests",
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _BenefitRow(
                icon: Icons.route_outlined,
                text: "Post rides in seconds",
                isDark: isDark,
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
              Get.offAllNamed(AppRoutes.shell);
            },
            child: Text('Not now', style: TextStyle(color: primary)),
          ),
        ),
      ],
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.text,
    required this.isDark,
  });
  final IconData icon;
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
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
    this.errorText,
    this.inputFormatters,
  });

  final String label;
  final String hint;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final String? errorText;
  final List<TextInputFormatter>? inputFormatters;

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
          inputFormatters: inputFormatters,
          decoration: appInputDecoration(
            context,
            hintText: hint,
            errorText: errorText,
            radius: 16,
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
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              ExoField(
                label: 'Car Make',
                hint: 'Toyota',
                onChanged: controller.setCarMake,
                errorText: controller.fieldError('carMake'),
              ),
              const SizedBox(height: 12),
              ExoField(
                label: 'Car Model',
                hint: 'Camry',
                onChanged: controller.setCarModel,
                errorText: controller.fieldError('carModel'),
              ),
              const SizedBox(height: 12),
              ExoField(
                label: 'Car Year',
                hint: '2022',
                keyboardType: TextInputType.number,
                onChanged: controller.setCarYear,
                errorText: controller.fieldError('carYear'),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
              ),
              const SizedBox(height: 12),
              ExoField(
                label: 'Car Color',
                hint: 'Silver',
                onChanged: controller.setCarColor,
                errorText: controller.fieldError('carColor'),
              ),
              const SizedBox(height: 12),
              ExoField(
                label: 'Plate Number',
                hint: 'ABC-1234',
                onChanged: controller.setPlateNumber,
                errorText: controller.fieldError('plateNumber'),
              ),
              const SizedBox(height: 12),
              ExoField(
                label: 'License Number',
                hint: 'LIC-987654',
                onChanged: controller.setLicenseNumber,
                errorText: controller.fieldError('licenseNumber'),
              ),
              const SizedBox(height: 12),
              ExoField(
                label: 'Insurance Info (optional)',
                hint: 'Provider / policy',
                onChanged: controller.setInsuranceInfo,
                errorText: controller.fieldError('insuranceInfo'),
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
