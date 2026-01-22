import 'dart:ui';

import 'package:get/get.dart';

import 'package:get/get.dart';

import '../../../shared/services/api_client.dart';
import '../Models/passenger_ride_request_model.dart';
import '../Services/passenger_ride_request_service.dart';

class BookRideDetailController extends GetxController {
  late RideRequestService _service;

  final isLoading = false.obs;

  @override
  void onInit() {
    _service = RideRequestService(Get.find<ApiClient>());
    super.onInit();
  }

  Future<void> requestRide({
    required PassengerRideRequestModel request,
    required VoidCallback onSuccess,
  }) async {
    try {
      isLoading.value = true;

      final result = await _service.createRideRequest(
        request: request,
      );

      // You can also store result if needed
      onSuccess();
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
