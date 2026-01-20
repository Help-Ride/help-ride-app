import 'package:get/get.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import '../../../shared/controllers/session_controller.dart';
import '../Services/passenger_edit_profile_service.dart';
import '../Models/passenger_edit_profile_request.dart';

class EditProfileController extends GetxController {
  final SessionController _sessionController;
  final PassengerProfileApi _api;

  EditProfileController(this._sessionController, this._api);

  // ── Loading & UI states ────────────────────────────────────────
  final RxBool isUpdating = false.obs;
  final RxBool isImageUploading = false.obs; // optional future use

  // ── Form fields (reactive) ─────────────────────────────────────
  final RxString name = ''.obs;
  final RxString phone = ''.obs;
  // email is read-only → we keep it as getter

  // ── Avatar handling ────────────────────────────────────────────
  final RxString localAvatarPath = ''.obs; // local file path for preview
  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    // Initialize form with current user values
    name.value = _sessionController.user.value?.name?.trim() ?? 'Passenger';
    phone.value = _sessionController.user.value?.phone?.trim() ?? '';
  }

  // ── Getters ─────────────────────────────────────────────────────
  String get userEmail => _sessionController.user.value?.email ?? '—';

  String? get existingAvatarUrl => _sessionController.user.value?.avatarUrl;

  String get displayAvatar {
    if (localAvatarPath.value.isNotEmpty) {
      return localAvatarPath.value;
    }
    return existingAvatarUrl ?? '';
  }

  String get initials {
    final n = name.value.trim();
    return n.isNotEmpty ? n[0].toUpperCase() : 'P';
  }

  // ── Image Picker ───────────────────────────────────────────────
  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (file != null) {
        localAvatarPath.value = file.path;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image\n$e');
    }
  }

  // ── Update Profile ─────────────────────────────────────────────
  Future<bool> updateProfile() async {
    final nameTrim = name.value.trim();
    final phoneTrim = phone.value.trim();

    if (nameTrim.isEmpty) {
      Get.snackbar('Validation', 'Name cannot be empty');
      return false;
    }

    // You can add more validation here (phone length, format...)

    try {
      isUpdating.value = true;

      // For now we use local path (as in your original code)
      // → later replace with real upload → URL
      final avatarToSend = localAvatarPath.value.isNotEmpty
          ? localAvatarPath.value
          : (existingAvatarUrl ?? '');

      final request = PassengerEditProfileRequest(
        name: nameTrim,
        phone: phoneTrim,
        providerAvatarUrl: avatarToSend,
      );

      final response = await _api.updateProfile(
        userId: _sessionController.user.value?.id ?? '',
        request: request,
      );

      // Update global user state
      _sessionController.updateUser(
        name: response.name,
        phone: response.phone,
        avatarUrl: response.providerAvatarUrl,
      );

      Get.snackbar('Success', 'Profile updated successfully');
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Update failed\n$e');
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  void resetForm() {
    name.value = _sessionController.user.value?.name?.trim() ?? 'Passenger';
    phone.value = _sessionController.user.value?.phone?.trim() ?? '';
    localAvatarPath.value = '';
  }
}