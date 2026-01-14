class RideCardVM {
  RideCardVM({
    required this.rideId,
    required this.driverId,
    required this.driverName,
    required this.driverInitials,
    required this.verified,
    required this.rating,
    required this.ridesCount,
    required this.departureLabel,
    required this.durationLabel,
    required this.seatsAvailable,
    required this.pricePerSeat,
  });

  final String rideId;
  final String driverId;

  // For now we don’t have driver profile -> placeholders
  final String driverName;
  final String driverInitials;
  final bool verified;
  final double rating;
  final int ridesCount;

  final String departureLabel;
  final String durationLabel;

  final int seatsAvailable;
  final int pricePerSeat;
}
