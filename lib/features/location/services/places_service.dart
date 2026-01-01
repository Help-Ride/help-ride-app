import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';
import '../models/place_result.dart';

class PlacesService {
  PlacesService({required String apiKey})
    : _places = FlutterGooglePlacesSdk(apiKey);

  final FlutterGooglePlacesSdk _places;

  Future<List<PlaceResult>> autocomplete(
    String query, {
    String? countryCode, // e.g. "ca"
  }) async {
    if (query.trim().length < 2) return [];

    final res = await _places.findAutocompletePredictions(
      query.trim(),
      countries: countryCode == null ? null : [countryCode],
      // sessionToken: optional (recommended later for billing optimization)
    );

    final preds = res.predictions;
    return preds
        .map((p) {
          final primary = p.primaryText ?? p.fullText ?? '';
          final secondary = p.secondaryText ?? '';
          return PlaceResult(
            placeId: p.placeId ?? '',
            primaryText: primary,
            secondaryText: secondary,
          );
        })
        .where((p) => p.placeId.isNotEmpty)
        .toList();
  }

  Future<PlaceResult?> details(String placeId) async {
    final res = await _places.fetchPlace(
      placeId,
      fields: [PlaceField.Address, PlaceField.Location, PlaceField.Name],
    );

    final place = res.place;
    if (place == null) return null;

    final name = place.name ?? '';
    final address = place.address ?? '';
    final loc = place.latLng;

    // Try to keep the UI-friendly primary/secondary structure
    final primary = name.isNotEmpty ? name : address;
    final secondary = name.isNotEmpty ? address : '';

    return PlaceResult(
      placeId: placeId,
      primaryText: primary,
      secondaryText: secondary,
      formattedAddress: address,
      lat: loc?.lat,
      lng: loc?.lng,
    );
  }
}
