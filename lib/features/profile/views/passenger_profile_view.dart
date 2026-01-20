import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/passenger_profile_controller.dart';
import '../widgets/passenger_profile_header.dart';
import '../widgets/passenger_profile_menu_item.dart';
import '../../../shared/controllers/session_controller.dart';
import '../../../core/routes/app_routes.dart';

class PassengerProfileView extends StatelessWidget {
  const PassengerProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PassengerProfileController>();

    final status = controller.sessionStatus;

    // 🔄 Checking session
    if (status == SessionStatus.unknown) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 🔒 Logged out
    if (status == SessionStatus.unauthenticated) {
      Future.microtask(() => Get.offAllNamed(AppRoutes.login));
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Profile Header
            PassengerProfileHeader(
              name: controller.userName,
              email: controller.userEmail,
              role: controller.userRole,
              initials: controller.userInitials,
              isVerified: controller.isVerified,
              avatarUrl: controller.avatarUrl,
            ),

            const SizedBox(height: 24),

            _sectionTitle('ACCOUNT'),
            _card([
              PassengerProfileMenuItem(
                icon: Icons.person_outline,
                title: 'Personal Information',
                onTap: controller.navigateToPersonalInfo,
              ),
              PassengerProfileMenuItem(
                icon: Icons.email_outlined,
                title: 'Email & Password',
                onTap: controller.navigateToEmailPassword,
              ),
              PassengerProfileMenuItem(
                icon: Icons.phone_outlined,
                title: 'Phone Number',
                onTap: controller.navigateToPhoneNumber,
              ),
              PassengerProfileMenuItem(
                icon: Icons.verified_user_outlined,
                title: 'Verification',
                onTap: controller.navigateToVerification,
                showDivider: false,
              ),
            ]),

            const SizedBox(height: 24),

            _sectionTitle('PREFERENCES'),
            _card([
              PassengerProfileMenuItem(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: controller.navigateToSettings,
              ),
              PassengerProfileMenuItem(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                onTap: controller.navigateToNotifications,
                showDivider: false,
              ),
            ]),

            const SizedBox(height: 24),

            _sectionTitle('SUPPORT'),
            _card([
              PassengerProfileMenuItem(
                icon: Icons.help_outline,
                title: 'Help Center',
                onTap: controller.navigateToHelpCenter,
              ),
              PassengerProfileMenuItem(
                icon: Icons.description_outlined,
                title: 'Terms & Privacy',
                onTap: controller.navigateToTermsPrivacy,
                showDivider: false,
              ),
            ]),

            const SizedBox(height: 16),

            _card([
              PassengerProfileMenuItem(
                icon: Icons.logout,
                title: 'Log out',
                onTap: controller.logout,
                isDestructive: true,
                showDivider: false,
              ),
            ]),

            const SizedBox(height: 24),

            Center(
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.black.withOpacity(0.4),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}
