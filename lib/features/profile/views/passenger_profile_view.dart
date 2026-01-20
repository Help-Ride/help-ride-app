// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../../shared/controllers/session_controller.dart';
// import '../../../core/theme/theme_controller.dart';
// import '../../../core/routes/app_routes.dart';
//
// class PassengerProfileView extends StatelessWidget {
//   const PassengerProfileView({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final session = Get.find<SessionController>();
//     final theme = Get.find<ThemeController>();
//
//     return Obx(() {
//       final status = session.status.value;
//
//       // 🔄 Still checking session
//       if (status == SessionStatus.unknown) {
//         return const Scaffold(body: Center(child: CircularProgressIndicator()));
//       }
//
//       // 🔒 Logged out
//       if (status == SessionStatus.unauthenticated) {
//         Future.microtask(() => Get.offAllNamed(AppRoutes.login));
//         return const Scaffold(body: Center(child: CircularProgressIndicator()));
//       }
//
//       // ✅ Authenticated
//       final user = session.user.value;
//       if (user == null) {
//         return const Scaffold(body: Center(child: CircularProgressIndicator()));
//       }
//
//       final name = user.name.isNotEmpty ? user.name : 'Passenger';
//       final email = user.email;
//       final role = user.driverProfile != null ? 'driver' : user.roleDefault;
//       final avatarUrl = user.avatarUrl;
//
//       return Scaffold(
//         appBar: AppBar(
//           title: const Text('Profile'),
//           actions: [
//             IconButton(
//               icon: const Icon(Icons.logout),
//               onPressed: () async {
//                 await session.logout();
//                 Get.offAllNamed(AppRoutes.login);
//               },
//             ),
//           ],
//         ),
//         body: ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//             _ProfileHeader(name: name, role: role, avatarUrl: avatarUrl),
//             const SizedBox(height: 16),
//
//             _SectionCard(
//               title: 'Contact Information',
//               children: [
//                 const _InfoRow(icon: Icons.phone, label: 'Phone', value: '—'),
//                 _InfoRow(icon: Icons.email, label: 'Email', value: email),
//                 const _InfoRow(
//                   icon: Icons.location_on,
//                   label: 'Location',
//                   value: '—',
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 16),
//
//             _SectionCard(
//               title: 'Account',
//               children: [
//                 _InfoRow(icon: Icons.verified_user, label: 'Role', value: role),
//                 _InfoRow(icon: Icons.badge, label: 'User ID', value: user.id),
//               ],
//             ),
//           ],
//         ),
//       );
//     });
//   }
// }
//
// /* -------------------- UI COMPONENTS -------------------- */
//
// class _ProfileHeader extends StatelessWidget {
//   const _ProfileHeader({
//     required this.name,
//     required this.role,
//     this.avatarUrl,
//   });
//
//   final String name;
//   final String role;
//   final String? avatarUrl;
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(16),
//         color: Theme.of(context).colorScheme.surface,
//       ),
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: 28,
//             backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
//                 ? NetworkImage(avatarUrl!)
//                 : null,
//             child: (avatarUrl == null || avatarUrl!.isEmpty)
//                 ? const Icon(Icons.person, size: 28)
//                 : null,
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   name,
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w800,
//                   ),
//                 ),
//                 const SizedBox(height: 6),
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 10,
//                     vertical: 4,
//                   ),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(999),
//                     color: Theme.of(
//                       context,
//                     ).colorScheme.primary.withOpacity(0.15),
//                   ),
//                   child: Text(
//                     role,
//                     style: TextStyle(
//                       color: Theme.of(context).colorScheme.primary,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _SectionCard extends StatelessWidget {
//   const _SectionCard({required this.title, required this.children});
//
//   final String title;
//   final List<Widget> children;
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(16),
//         color: Theme.of(context).colorScheme.surface,
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
//           ),
//           const SizedBox(height: 12),
//           ...children,
//         ],
//       ),
//     );
//   }
// }
//
// class _InfoRow extends StatelessWidget {
//   const _InfoRow({
//     required this.icon,
//     required this.label,
//     required this.value,
//   });
//
//   final IconData icon;
//   final String label;
//   final String value;
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Row(
//         children: [
//           CircleAvatar(radius: 18, child: Icon(icon, size: 18)),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Theme.of(context).hintColor,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   value,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/passenger_profile_controller.dart';
import '../widgets/passenger_profile_header.dart';
import '../widgets/passenger_profile_menu_item.dart';
import '../../../shared/controllers/session_controller.dart';
import '../../../core/routes/app_routes.dart';

class PassengerProfileView extends GetView<PassengerProfileController> {
  const PassengerProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(PassengerProfileController()); // 👈 ADD THIS LINE

    return Obx(() {
      final status = controller.sessionStatus;

      // 🔄 Still checking session
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
          centerTitle: false,
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

              // ACCOUNT Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'ACCOUNT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withOpacity(0.4),
                    letterSpacing: 0.5,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
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
                child: Column(
                  children: [
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
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // PREFERENCES Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'PREFERENCES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withOpacity(0.4),
                    letterSpacing: 0.5,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
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
                child: Column(
                  children: [
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
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // SUPPORT Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'SUPPORT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withOpacity(0.4),
                    letterSpacing: 0.5,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
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
                child: Column(
                  children: [
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
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Log Out Button
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
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
                child: PassengerProfileMenuItem(
                  icon: Icons.logout,
                  title: 'Log out',
                  onTap: controller.logout,
                  isDestructive: true,
                  showDivider: false,
                ),
              ),

              const SizedBox(height: 24),

              // Version
              Center(
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.black.withOpacity(0.3),
                    height: 1.3,
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      );
    });
  }
}