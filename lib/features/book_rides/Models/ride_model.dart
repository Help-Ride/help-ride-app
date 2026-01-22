// ride.dart - Model Class
class Ride {
  final String driverName;
  final String driverInitials;
  final double rating;
  final int totalRides;
  final String departureTime;
  final int duration;
  final int availableSeats;
  final double pricePerSeat;
  final bool isVerified;
  final String? vehicleModel;
  final String? vehicleColor;
  final String? licensePlate;
  final int? vehicleYear;
  final List<String>? amenities;
  final String? pickupInstructions;
  final String? pickupLocation;
  final String? pickupSubtitle;
  final String? destinationLocation;
  final String? destinationSubtitle;

  Ride({
    required this.driverName,
    required this.driverInitials,
    required this.rating,
    required this.totalRides,
    required this.departureTime,
    required this.duration,
    required this.availableSeats,
    required this.pricePerSeat,
    this.isVerified = false,
    this.vehicleModel,
    this.vehicleColor,
    this.licensePlate,
    this.vehicleYear,
    this.amenities,
    this.pickupInstructions,
    this.pickupLocation,
    this.pickupSubtitle,
    this.destinationLocation,
    this.destinationSubtitle,
  });
}