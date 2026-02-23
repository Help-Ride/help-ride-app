import 'package:get/get.dart';
import 'package:help_ride/features/home/services/drivers_api.dart';
import 'package:help_ride/shared/utils/input_validators.dart';
import '../routes/driver_routes.dart';
import '../../../shared/controllers/session_controller.dart';
import '../../../shared/services/api_client.dart';

class DriverOnboardingController extends GetxController {
  final loading = false.obs;
  final error = RxnString();
  final fieldErrors = <String, String>{}.obs;

  String carMake = '';
  String carModel = '';
  String carYear = '';
  String carColor = '';
  String plateNumber = '';
  String licenseNumber = '';
  String insuranceInfo = '';

  void setCarMake(String v) {
    carMake = v.trim();
    _clearFieldError('carMake');
    error.value = null;
  }

  void setCarModel(String v) {
    carModel = v.trim();
    _clearFieldError('carModel');
    error.value = null;
  }

  void setCarYear(String v) {
    carYear = v.trim();
    _clearFieldError('carYear');
    error.value = null;
  }

  void setCarColor(String v) {
    carColor = v.trim();
    _clearFieldError('carColor');
    error.value = null;
  }

  void setPlateNumber(String v) {
    plateNumber = v.trim();
    _clearFieldError('plateNumber');
    error.value = null;
  }

  void setLicenseNumber(String v) {
    licenseNumber = v.trim();
    _clearFieldError('licenseNumber');
    error.value = null;
  }

  void setInsuranceInfo(String v) {
    insuranceInfo = v.trim();
    _clearFieldError('insuranceInfo');
    error.value = null;
  }

  String? fieldError(String key) => fieldErrors[key];

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

    if (!_validateFields(showErrors: true)) {
      error.value = 'Please fix highlighted fields.';
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

      // Close only when opened as a dedicated onboarding route.
      if (Get.currentRoute == DriverRoutes.onboarding &&
          (Get.key.currentState?.canPop() ?? false)) {
        Get.back();
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  bool _validateFields({required bool showErrors}) {
    final errors = <String, String?>{
      'carMake': InputValidators.requiredText(carMake, fieldLabel: 'Car make'),
      'carModel': InputValidators.requiredText(
        carModel,
        fieldLabel: 'Car model',
      ),
      'carYear': InputValidators.optionalYear(carYear),
      'carColor': null,
      'plateNumber': InputValidators.requiredText(
        plateNumber,
        fieldLabel: 'Plate number',
      ),
      'licenseNumber': InputValidators.requiredText(
        licenseNumber,
        fieldLabel: 'License number',
      ),
      'insuranceInfo': null,
    };

    if (showErrors) {
      fieldErrors.clear();
      errors.forEach((key, value) {
        if (value != null) fieldErrors[key] = value;
      });
    }

    return errors.values.every((msg) => msg == null);
  }

  void _clearFieldError(String key) {
    if (!fieldErrors.containsKey(key)) return;
    fieldErrors.remove(key);
  }
}
