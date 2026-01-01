
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:help_ride/core/constants/app_images.dart';
import '../controllers/session_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../features/auth/routes/auth_routes.dart';

class SplashGate extends StatelessWidget {
  const SplashGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();

    return Obx(() {
      final s = session.status.value;
      final onboarded = session.isOnboardingCompleted.value;


      // if (s == SessionStatus.authenticated) {
      //   Future.microtask(() => Get.offAllNamed(AppRoutes.home));
      // } else if (s == SessionStatus.unauthenticated) {
      //   // Future.microtask(() => Get.offAllNamed(AuthRoutes.login));
      //   Future.microtask(() => Get.offAllNamed(AuthRoutes.onboarding));
      // }

      if (s == SessionStatus.authenticated) {
        Future.microtask(() => Get.offAllNamed(AppRoutes.home));
      } else if (s == SessionStatus.unauthenticated) {
        if (onboarded) {
          /// ✅ Already onboarded → Login
          Future.microtask(() => Get.offAllNamed(AuthRoutes.login));
        } else {
          /// ✅ First time → Onboarding
          Future.microtask(() => Get.offAllNamed(AuthRoutes.onboarding));
        }
      }

      return Scaffold(
        body: Container(
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF26D0A5), // Light turquoise
                Color(0xFF1BA582), // Darker teal
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Container
              Container(
                width: 100,
                height: 100,
                padding: EdgeInsets.symmetric(horizontal: 20,vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Image.asset(AppImages.carImage,height: 48,width: 48,)
              ),
              const SizedBox(height: 24),

              // App Name
              const Text(
                'HelpRide',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Tagline
              const Text(
                'Your journey, shared',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.white70,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 200),

              // Loading Indicator
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 16),

              // Loading Text
              const Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
