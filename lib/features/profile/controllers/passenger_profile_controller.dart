import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/controllers/session_controller.dart';
import '../../../core/routes/app_routes.dart';
import '../Models/passenger_edit_profile_model.dart';
import '../Models/passenger_edit_profile_request.dart';
import '../Services/passenger_edit_profile_service.dart';

class PassengerProfileController extends GetxController {
  final SessionController _sessionController;
  final PassengerProfileApi _passengerProfileApi;

  PassengerProfileController(
      this._sessionController,
      this._passengerProfileApi,
      );

  final RxString _phoneNumber = ''.obs;
  final RxBool isUpdating = false.obs;

  /* ───────────────── USER GETTERS ───────────────── */

  String get userId => _sessionController.user.value?.id ?? '';

  String get userName =>
      _sessionController.user.value?.name.isNotEmpty == true
          ? _sessionController.user.value!.name
          : 'Passenger';

  String get userEmail => _sessionController.user.value?.email ?? '—';

  String get userPhone => _phoneNumber.value;

  String? get avatarUrl => _sessionController.user.value?.avatarUrl;

  String get userRole =>
      _sessionController.user.value?.roleDefault ?? 'passenger';

  bool get isVerified => true;

  SessionStatus get sessionStatus => _sessionController.status.value;

  String get userInitials {
    final name = userName.trim();
    if (name.isEmpty) return 'P';

    final parts = name.split(' ');
    return parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name[0].toUpperCase();
  }

  @override
  void onInit() {
    super.onInit();
    _phoneNumber.value = _sessionController.user.value?.phone ?? '';
  }

  /* ───────────────── ACTIONS ───────────────── */

  Future<void> logout() async {
    await _sessionController.logout();
    Get.offAllNamed(AppRoutes.login);
  }

  /* ───────────────── NAVIGATION HELPERS ───────────────── */

  void navigateToPersonalInfo() =>
      Get.snackbar('Navigation', 'Personal Info');

  void navigateToEmailPassword() =>
      Get.snackbar('Navigation', 'Email & Password');

  void navigateToPhoneNumber() =>
      Get.snackbar('Navigation', 'Phone Number');

  void navigateToVerification() =>
      Get.snackbar('Navigation', 'Verification');

  void navigateToSettings() =>
      Get.snackbar('Navigation', 'Settings');

  void navigateToNotifications() =>
      Get.snackbar('Navigation', 'Notifications');

  void navigateToHelpCenter() =>
      Get.snackbar('Navigation', 'Help Center');

  void navigateToTermsPrivacy() =>
      Get.snackbar('Navigation', 'Terms & Privacy');
}
