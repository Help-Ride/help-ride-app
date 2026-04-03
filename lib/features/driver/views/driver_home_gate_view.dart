import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:help_ride/features/driver/controllers/driver_onboarding_controller.dart';
import 'package:help_ride/features/driver/widgets/driver_home.dart';
import 'package:help_ride/features/profile/controllers/profile_controller.dart';
import 'package:help_ride/features/profile/models/driver_document.dart';
import '../controllers/driver_gate_controller.dart';
import 'driver_onboarding_view.dart';

class DriverHomeGateView extends GetView<DriverGateController> {
  const DriverHomeGateView({super.key});

  @override
  Widget build(BuildContext context) {
    final profileController = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController(), permanent: false);

    return Obx(() {
      if (!controller.hasDriverProfile) {
        if (!Get.isRegistered<DriverOnboardingController>()) {
          Get.lazyPut<DriverOnboardingController>(
            () => DriverOnboardingController(),
            fenix: true,
          );
        }
        return const DriverOnboardingView();
      }

      if (profileController.docsLoading.value &&
          profileController.driverDocuments.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (!_hasCompletedDriverOnboarding(profileController.driverDocuments)) {
        if (!Get.isRegistered<DriverOnboardingController>()) {
          Get.lazyPut<DriverOnboardingController>(
            () => DriverOnboardingController(),
            fenix: true,
          );
        }
        return const DriverOnboardingView();
      }

      return const DriverHomeView();
    });
  }
}

const Map<String, Set<String>> _requiredOnboardingDocumentTypes = {
  'selfie': {'selfie', 'driver_selfie', 'photo_selfie'},
  'license': {'license', 'driver_license'},
  'insurance': {'insurance', 'insurance_proof', 'proof_of_insurance'},
};

bool _hasCompletedDriverOnboarding(List<DriverDocument> documents) {
  for (final acceptedTypes in _requiredOnboardingDocumentTypes.values) {
    final hasDocument = documents.any((document) {
      final type = document.type.trim().toLowerCase().replaceAll(
        RegExp(r'[\s\-]'),
        '_',
      );
      final status = (document.status ?? '').trim().toLowerCase();
      if (!acceptedTypes.contains(type)) return false;
      return status != 'rejected';
    });
    if (!hasDocument) return false;
  }
  return true;
}
