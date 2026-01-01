import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/place_result.dart';

/// Google Places REST (Web Service) wrapper.
///
/// Why: avoids native Android/iOS SDK plugin breakage.
///
/// Required on Google Cloud:
/// - Enable *Places API* (and optionally *Geocoding API* if you extend later)
/// - Use a restricted API key (HTTP referrers are for web; for mobile keep key
///   server-side ideally; for MVP you can use it client-side but restrict APIs).
class PlacesService {
  PlacesService({required String apiKey, http.Client? client})
    : _apiKey = apiKey,
      _client = client ?? http.Client();

  final String _apiKey;
  final http.Client _client;

  static const String _autocompleteUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const String _detailsUrl =
      'https://maps.googleapis.com/maps/api/place/details/json';

  /// Autocomplete predictions.
  ///
  /// [countryCode] example: "ca".
  /// [sessionToken] optional but recommended (billing optimization & better results).
  Future<List<PlaceResult>> autocomplete(
    String query, {
    String? countryCode,
    String? sessionToken,
  }) async {
    final q = query.trim();
    if (q.length < 2) return [];

    final params = <String, String>{
      'input': q,
      'key': _apiKey,
      // You can switch to "(cities)" or other types later.
      // 'types': 'geocode',
    };

    if (countryCode != null && countryCode.trim().isNotEmpty) {
      // REST API uses "components=country:ca".
      params['components'] = 'country:${countryCode.trim().toLowerCase()}';
    }

    if (sessionToken != null && sessionToken.trim().isNotEmpty) {
      params['sessiontoken'] = sessionToken.trim();
    }

    final uri = Uri.parse(_autocompleteUrl).replace(queryParameters: params);
    final resp = await _client.get(uri);

    if (resp.statusCode != 200) {
      throw Exception(
        'Places autocomplete HTTP ${resp.statusCode}: ${resp.body}',
      );
    }

    final jsonMap = jsonDecode(resp.body) as Map<String, dynamic>;
    final status = (jsonMap['status'] as String?) ?? 'UNKNOWN';

    // Common non-fatal statuses: ZERO_RESULTS.
    if (status != 'OK' && status != 'ZERO_RESULTS') {
      final msg = (jsonMap['error_message'] as String?) ?? 'No error_message';
      throw Exception('Places autocomplete failed: $status ($msg)');
    }

    final preds = (jsonMap['predictions'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();

    return preds
        .map((p) {
          final placeId = (p['place_id'] as String?) ?? '';

          // Google returns these structures:
          // - structured_formatting.main_text
          // - structured_formatting.secondary_text
          final structured =
              (p['structured_formatting'] as Map<String, dynamic>?) ??
              const <String, dynamic>{};
          final primary =
              (structured['main_text'] as String?) ??
              (p['description'] as String?) ??
              '';
          final secondary = (structured['secondary_text'] as String?) ?? '';

          return PlaceResult(
            placeId: placeId,
            primaryText: primary,
            secondaryText: secondary,
          );
        })
        .where((p) => p.placeId.isNotEmpty)
        .toList();
  }

  /// Fetch place details.
  ///
  /// Uses the REST details endpoint. Returns address + lat/lng.
  Future<PlaceResult?> details(String placeId, {String? sessionToken}) async {
    final id = placeId.trim();
    if (id.isEmpty) return null;

    final params = <String, String>{
      'place_id': id,
      'key': _apiKey,
      // Keep it minimal to reduce payload.
      'fields': 'place_id,name,formatted_address,geometry',
    };

    if (sessionToken != null && sessionToken.trim().isNotEmpty) {
      params['sessiontoken'] = sessionToken.trim();
    }

    final uri = Uri.parse(_detailsUrl).replace(queryParameters: params);
    final resp = await _client.get(uri);

    if (resp.statusCode != 200) {
      throw Exception('Places details HTTP ${resp.statusCode}: ${resp.body}');
    }

    final jsonMap = jsonDecode(resp.body) as Map<String, dynamic>;
    final status = (jsonMap['status'] as String?) ?? 'UNKNOWN';

    if (status != 'OK') {
      final msg = (jsonMap['error_message'] as String?) ?? 'No error_message';
      throw Exception('Places details failed: $status ($msg)');
    }

    final result =
        (jsonMap['result'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};

    final name = (result['name'] as String?) ?? '';
    final address = (result['formatted_address'] as String?) ?? '';

    final geometry =
        (result['geometry'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
    final location =
        (geometry['location'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
    final lat = (location['lat'] as num?)?.toDouble();
    final lng = (location['lng'] as num?)?.toDouble();

    // UI-friendly primary/secondary
    final primary = name.isNotEmpty ? name : address;
    final secondary = name.isNotEmpty ? address : '';

    return PlaceResult(
      placeId: id,
      primaryText: primary,
      secondaryText: secondary,
      formattedAddress: address,
      lat: lat,
      lng: lng,
    );
  }

  void dispose() {
    _client.close();
  }
}
