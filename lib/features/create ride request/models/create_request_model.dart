import 'package:flutter/material.dart';

class RideRequest {
  String? pickupLocation;
  String? destination;
  DateTime? date;
  TimeOfDay? time;
  int? numberOfSeats;
  double? maxPricePerSeat;
  String? additionalNotes;

  RideRequest({
    this.pickupLocation,
    this.destination,
    this.date,
    this.time,
    this.numberOfSeats,
    this.maxPricePerSeat,
    this.additionalNotes,
  });

  bool get isValid {
    return pickupLocation != null &&
        pickupLocation!.isNotEmpty &&
        destination != null &&
        destination!.isNotEmpty &&
        date != null &&
        time != null &&
        numberOfSeats != null &&
        numberOfSeats! > 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'pickupLocation': pickupLocation,
      'destination': destination,
      'date': date?.toIso8601String(),
      'time': '${time?.hour}:${time?.minute}',
      'numberOfSeats': numberOfSeats,
      'maxPricePerSeat': maxPricePerSeat,
      'additionalNotes': additionalNotes,
    };
  }
}
