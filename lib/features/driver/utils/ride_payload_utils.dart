const Map<String, String> rideAmenityLabelToApi = {
  'AC': 'ac',
  'Music': 'music',
  'WiFi': 'wifi',
  'Pet-friendly': 'pet_friendly',
  'Luggage space': 'luggage_space',
  'Child seat': 'child_seat',
};

List<String> selectedRideAmenitiesForApi(Map<String, bool> amenitiesByLabel) {
  final selected = <String>[];
  for (final entry in amenitiesByLabel.entries) {
    if (entry.value != true) continue;
    final mapped = rideAmenityLabelToApi[entry.key];
    selected.add(mapped ?? _normalizeAmenityToken(entry.key));
  }
  return selected;
}

void applyRideAmenitiesFromApi(
  Map<String, bool> amenitiesByLabel,
  List<String> amenitiesFromApi,
) {
  final selected = amenitiesFromApi
      .map(_normalizeAmenityToken)
      .where((token) => token.isNotEmpty)
      .toSet();

  amenitiesByLabel.updateAll((label, _) {
    final mapped =
        rideAmenityLabelToApi[label] ?? _normalizeAmenityToken(label);
    return selected.contains(mapped) ||
        selected.contains(_normalizeAmenityToken(label));
  });
}

List<String> parseRideStopsCsv(String raw) {
  return raw
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
}

String? normalizeRideAdditionalNotes(String raw) {
  final trimmed = raw.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _normalizeAmenityToken(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'[\s\-]+'), '_');
}
