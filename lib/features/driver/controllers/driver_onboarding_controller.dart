import 'package:get/get.dart';
import 'package:help_ride/features/home/services/drivers_api.dart';
import '../../../shared/controllers/session_controller.dart';
import '../../../shared/services/api_client.dart';

class DriverOnboardingController extends GetxController {
  final loading = false.obs;
  final error = RxnString();

  String carMake = '';
  String carModel = '';
  String carYear = '';
  String carColor = '';
  String plateNumber = '';
  String licenseNumber = '';
  String insuranceInfo = '';

  void setCarMake(String v) => carMake = v.trim();
  void setCarModel(String v) => carModel = v.trim();
  void setCarYear(String v) => carYear = v.trim();
  void setCarColor(String v) => carColor = v.trim();
  void setPlateNumber(String v) => plateNumber = v.trim();
  void setLicenseNumber(String v) => licenseNumber = v.trim();
  void setInsuranceInfo(String v) => insuranceInfo = v.trim();

  late final DriversApi _api;
  final SessionController _session = Get.find<SessionController>();

  @override
  Future<void> onInit() async {
    super.onInit();
    final client = await ApiClient.create();
    _api = DriversApi(client);
  }

  Future<void> submit() async {
    error.value = null;

    if (carMake.isEmpty ||
        carModel.isEmpty ||
        plateNumber.isEmpty ||
        licenseNumber.isEmpty) {
      error.value = 'Fill car make, model, plate number and license number.';
      return;
    }

    loading.value = true;
    try {
      await _api.createDriverProfile(
        carMake: carMake,
        carModel: carModel,
        carYear: carYear.isEmpty ? null : carYear,
        carColor: carColor.isEmpty ? null : carColor,
        plateNumber: plateNumber,
        licenseNumber: licenseNumber,
        insuranceInfo: insuranceInfo.isEmpty ? null : insuranceInfo,
      );

      // ✅ refresh session so driverProfile becomes available
      await _session.bootstrap();

      // ✅ go back to driver gate; it will now show dashboard
      Get.back();
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }
}
