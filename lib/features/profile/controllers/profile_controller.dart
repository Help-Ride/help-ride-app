import 'package:get/get.dart';
import 'package:help_ride/shared/controllers/session_controller.dart';
import 'package:help_ride/shared/models/user.dart';
import '../../../shared/services/api_client.dart';
import '../services/profile_api.dart';

class ProfileController extends GetxController {
  late final ProfileApi _api;
  late final SessionController _session;

  final driverProfile = Rxn<DriverProfile>();
  final loading = false.obs;
  final driverLoading = false.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    _session = Get.find<SessionController>();
    final client = await ApiClient.create();
    _api = ProfileApi(client);
    driverProfile.value = _session.user.value?.driverProfile;
    await refreshDriverProfile();
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
