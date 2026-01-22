import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/create_request_model.dart';

class CreateRideRequestController extends GetxController {
  final pickupLocationController = TextEditingController();
  final destinationController = TextEditingController();
  final numberOfSeatsController = TextEditingController();
  final maxPriceController = TextEditingController();
  final additionalNotesController = TextEditingController();

  final Rx<DateTime?> selectedDate = Rx<DateTime?>(null);
  final Rx<TimeOfDay?> selectedTime = Rx<TimeOfDay?>(null);
  final RxBool isLoading = false.obs;

  final rideRequest = RideRequest().obs;

  @override
  void onClose() {
    pickupLocationController.dispose();
    destinationController.dispose();
    numberOfSeatsController.dispose();
    maxPriceController.dispose();
    additionalNotesController.dispose();
    super.onClose();
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF00BFA5),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1A1A1A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      selectedDate.value = picked;
      rideRequest.value.date = picked;
    }
  }

  Future<void> selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime.value ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF00BFA5),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1A1A1A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      selectedTime.value = picked;
      rideRequest.value.time = picked;
    }
  }

  void createRideRequest() {
    rideRequest.value.pickupLocation = pickupLocationController.text;
    rideRequest.value.destination = destinationController.text;
    rideRequest.value.numberOfSeats = int.tryParse(numberOfSeatsController.text);
    rideRequest.value.maxPricePerSeat = double.tryParse(maxPriceController.text);
    rideRequest.value.additionalNotes = additionalNotesController.text;

    if (!rideRequest.value.isValid) {
      Get.snackbar(
        'Error',
        'Please fill in all required fields',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        snackPosition: SnackPosition.BOTTOM,
        margin: EdgeInsets.all(16),
      );
      return;
    }

    isLoading.value = true;

    // Simulate API call
    Future.delayed(Duration(seconds: 2), () {
      isLoading.value = false;

      Get.snackbar(
        'Success',
        'Ride request created successfully!',
        backgroundColor: Color(0xFF00BFA5).withOpacity(0.1),
        colorText: Color(0xFF00BFA5),
        snackPosition: SnackPosition.BOTTOM,
        margin: EdgeInsets.all(16),
      );

      // Navigate back or to another screen
      // Get.back();
    });
  }

  String formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  String formatTime(TimeOfDay? time) {
    if (time == null) return '';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}