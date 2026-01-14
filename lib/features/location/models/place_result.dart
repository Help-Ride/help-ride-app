class PlaceResult {
  final String placeId;
  final String primaryText;
  final String secondaryText;
  final String? formattedAddress;
  final double? lat;
  final double? lng;

  const PlaceResult({
    required this.placeId,
    required this.primaryText,
    required this.secondaryText,
    this.formattedAddress,
    this.lat,
    this.lng,
  });

  String get displayText =>
      secondaryText.isEmpty ? primaryText : "$primaryText, $secondaryText";
}
