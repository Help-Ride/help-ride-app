import 'dart:io';

import 'package:get/get.dart';
import 'package:help_ride/shared/controllers/session_controller.dart';
import 'package:help_ride/shared/models/user.dart';
import '../../../shared/services/api_client.dart';
import '../models/driver_document.dart';
import '../services/profile_api.dart';

class ProfileController extends GetxController {
  late final ProfileApi _api;
  late final SessionController _session;

  final driverProfile = Rxn<DriverProfile>();
  final driverDocuments = <DriverDocument>[].obs;
  final loading = false.obs;
  final driverLoading = false.obs;
  final docsLoading = false.obs;
  final docsUploading = false.obs;
  final docsError = RxnString();

  @override
  Future<void> onInit() async {
    super.onInit();
    _session = Get.find<SessionController>();
    final client = await ApiClient.create();
    _api = ProfileApi(client);
    driverProfile.value = _session.user.value?.driverProfile;
    await refreshDriverProfile();
    await refreshDriverDocuments();
  }

  Future<void> refreshDriverProfile() async {
    final userId = _session.user.value?.id ?? '';
    if (userId.isEmpty) return;
    driverLoading.value = true;
    try {
      final profile = await _api.getDriverProfile(userId);
      if (profile != null) {
        driverProfile.value = profile;
      }
    } catch (_) {
      // Ignore missing driver profile for passengers.
    } finally {
      driverLoading.value = false;
    }
  }

  Future<void> refreshDriverDocuments({bool silent = false}) async {
    final userId = _session.user.value?.id ?? '';
    if (userId.isEmpty) return;
    if (!silent) {
      docsLoading.value = true;
    }
    docsError.value = null;
    try {
      final docs = await _api.getDriverDocuments(userId);
      driverDocuments.assignAll(docs);
    } catch (_) {
      driverDocuments.clear();
      docsError.value = 'Could not load documents right now.';
    } finally {
      docsLoading.value = false;
    }
  }

  Future<void> uploadDriverLicenseDocument({
    required String filePath,
    required String fileName,
    required String mimeType,
  }) async {
    final userId = _session.user.value?.id ?? '';
    if (userId.isEmpty) return;
    docsUploading.value = true;
    docsError.value = null;
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('Selected file is empty.');
      }

      final presign = await _api.getDriverDocumentPresign(
        userId,
        type: 'license',
        fileName: fileName,
        mimeType: mimeType,
      );

      await _api.uploadFileToPresignedUrl(
        uploadUrl: presign.uploadUrl,
        bytes: bytes,
        mimeType: mimeType,
      );
      await refreshDriverDocuments(silent: true);
    } catch (e) {
      docsError.value = e.toString();
      rethrow;
    } finally {
      docsUploading.value = false;
    }
  }

  Future<void> updateUserProfile({
    required String name,
    required String phone,
    required String avatarUrl,
  }) async {
    final userId = _session.user.value?.id ?? '';
    if (userId.isEmpty) return;
    loading.value = true;
    try {
      await _api.updateUserProfile(
        userId,
        name: name.trim().isEmpty ? null : name.trim(),
        phone: phone.trim().isEmpty ? null : phone.trim(),
        providerAvatarUrl: avatarUrl.trim().isEmpty ? null : avatarUrl.trim(),
      );
      await _session.bootstrap();
    } finally {
      loading.value = false;
    }
  }

  Future<void> upsertDriverProfile({
    required String carMake,
    required String carModel,
    String? carYear,
    String? carColor,
    required String plateNumber,
    required String licenseNumber,
    String? insuranceInfo,
  }) async {
    final userId = _session.user.value?.id ?? '';
    if (userId.isEmpty) return;
    driverLoading.value = true;
    try {
      final existing = driverProfile.value;
      if (existing == null) {
        await _api.createDriverProfile(
          carMake: carMake.trim(),
          carModel: carModel.trim(),
          carYear: carYear?.trim(),
          carColor: carColor?.trim(),
          plateNumber: plateNumber.trim(),
          licenseNumber: licenseNumber.trim(),
          insuranceInfo: insuranceInfo?.trim(),
        );
      } else {
        await _api.updateDriverProfile(
          userId,
          carMake: carMake.trim(),
          carModel: carModel.trim(),
          carYear: carYear?.trim(),
          carColor: carColor?.trim(),
          plateNumber: plateNumber.trim(),
          licenseNumber: licenseNumber.trim(),
          insuranceInfo: insuranceInfo?.trim(),
        );
      }
      await refreshDriverProfile();
      await _session.bootstrap();
    } finally {
      driverLoading.value = false;
    }
  }
}
