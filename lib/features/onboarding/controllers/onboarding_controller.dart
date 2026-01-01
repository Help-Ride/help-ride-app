import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:help_ride/features/auth/routes/auth_routes.dart';

import '../../../core/constants/app_images.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/controllers/session_controller.dart';

class OnboardingController extends GetxController {
  final pageController = PageController();
  var pageIndex = 0.obs; // RxInt → var with .obs

  final pages = [
    {
      "image": AppImages.onboarding1,
      "icon": AppImages.carImage,
      "title": "Find Your Ride",
      "subtitle":
      "Search and book rides with verified drivers going your way. Safe, affordable, and convenient.",
    },
    {
      "image": AppImages.onboarding1,
      "icon": AppImages.carImage,
      "title": "Share & Save Money",
      "subtitle":
      "Carpool with trusted passengers or drivers. Split costs and reduce your travel expenses instantly.",
    },
    {
      "image": AppImages.onboarding1,
      "icon": AppImages.carImage,
      "title": "Travel with Confidence",
      "subtitle":
      "Real-time tracking, verified profiles, and 24/7 support ensure every ride is safe and reliable.",
    },
  ];

  void nextPage() {
    if (pageIndex.value < pages.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      final session = Get.find<SessionController>();
      session.completeOnboarding();
      Get.offAllNamed(AuthRoutes.login);
    }
  }

  void skip() {
    final session = Get.find<SessionController>();
    session.completeOnboarding();
    Get.offAllNamed(AuthRoutes.login);
  }


  void onPageChanged(int index) {
    pageIndex.value = index;
    update(); // Important for GetBuilder
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
