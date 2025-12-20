import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/routes/app_routes.dart';

class OnboardingController extends GetxController {
  final pageController = PageController();
  final currentIndex = 0.obs;

  final _box = GetStorage();
  static const _key = 'onboarding_seen';

  void onPageChanged(int i) => currentIndex.value = i;

  void next() {
    if (currentIndex.value < 2) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void skip() {
    pageController.animateToPage(
      2,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> finish() async {
    await _box.write(_key, true);
    Get.offAllNamed(
      AppRoutes.login,
    ); // or AppRoutes.gate if you want gate to decide
  }

  static bool seen() {
    final box = GetStorage();
    return box.read(_key) == true;
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
