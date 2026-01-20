import 'package:get/get.dart';
import '../../../shared/controllers/session_controller.dart';
import '../../../core/routes/app_routes.dart';

class PassengerProfileController extends GetxController {
  final SessionController _sessionController = Get.find<SessionController>();

  // User info getters
  String get userName {
    final user = _sessionController.user.value;
    if (user == null) return 'Passenger';
    return user.name.isNotEmpty ? user.name : 'Passenger';
  }

  String get userEmail {
    final user = _sessionController.user.value;
    return user?.email ?? '—';
  }

  String get userRole {
    final user = _sessionController.user.value;
    if (user == null) return 'passenger';
    return user.driverProfile != null ? 'driver' : user.roleDefault;
  }

  String? get avatarUrl {
    final user = _sessionController.user.value;
    return user?.avatarUrl;
  }

  String get userId {
    final user = _sessionController.user.value;
    return user?.id ?? '—';
  }

  bool get isVerified {
    // You can add verification logic here
    return true;
  }

  SessionStatus get sessionStatus => _sessionController.status.value;

  // Get user initials for avatar
  String get userInitials {
    final name = userName;
    if (name.isEmpty || name == 'Passenger') return 'P';

    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  // Actions
  Future<void> logout() async {
    await _sessionController.logout();
    Get.offAllNamed(AppRoutes.login);
  }

  void navigateToPersonalInfo() {
    // Add navigation logic
    Get.snackbar('Navigation', 'Personal Information');
  }

  void navigateToEmailPassword() {
    // Add navigation logic
    Get.snackbar('Navigation', 'Email & Password');
  }

  void navigateToPhoneNumber() {
    // Add navigation logic
    Get.snackbar('Navigation', 'Phone Number');
  }

  void navigateToVerification() {
    // Add navigation logic
    Get.snackbar('Navigation', 'Verification');
  }

  void navigateToSettings() {
    // Add navigation logic
    Get.snackbar('Navigation', 'Settings');
  }

  void navigateToNotifications() {
    // Add navigation logic
    Get.snackbar('Navigation', 'Notifications');
  }

  void navigateToHelpCenter() {
    // Add navigation logic
    Get.snackbar('Navigation', 'Help Center');
  }

  void navigateToTermsPrivacy() {
    // Add navigation logic
    Get.snackbar('Navigation', 'Terms & Privacy');
  }
}