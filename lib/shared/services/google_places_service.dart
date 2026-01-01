import 'dart:convert';
import 'package:http/http.dart' as http;

class PlacesPrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlacesPrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlacesPrediction.fromJson(Map<String, dynamic> j) {
    final structured =
        j['structured_formatting'] as Map<String, dynamic>? ?? {};
    return PlacesPrediction(
      placeId: j['place_id'] as String,
      description: j['description'] as String,
      mainText: (structured['main_text'] ?? j['description']) as String,
      secondaryText: (structured['secondary_text'] ?? '') as String,
    );
  }
}

class PlaceDetailsResult {
  final String formattedAddress;
  final double? lat;
  final double? lng;

  PlaceDetailsResult({
    required this.formattedAddress,
    required this.lat,
    required this.lng,
  });
}

class GooglePlacesService {
  GooglePlacesService(this.apiKey);

  final String apiKey;

  Future<List<PlacesPrediction>> autocomplete({
    required String input,
    required String sessionToken,
    String? countryCode, // "ca"
  }) async {
    final q = input.trim();
    if (q.isEmpty) return [];

    final uri =
        Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', {
          'input': q,
          'key': apiKey,
          'sessiontoken': sessionToken,
          if (countryCode != null) 'components': 'country:$countryCode',
        });

    final res = await http.get(uri);
    final body = jsonDecode(res.body) as Map<String, dynamic>;

    final status = body['status'] as String?;
    if (status != 'OK' && status != 'ZERO_RESULTS') {
      throw Exception(
        'Places autocomplete failed: $status ${body['error_message'] ?? ''}',
      );
    }

    final preds = (body['predictions'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(PlacesPrediction.fromJson)
        .toList();

    return preds;
  }

  Future<PlaceDetailsResult> placeDetails({
    required String placeId,
    required String sessionToken,
  }) async {
    final uri =
        Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
          'place_id': placeId,
          'fields': 'formatted_address,geometry/location',
          'key': apiKey,
          'sessiontoken': sessionToken,
        });

    final res = await http.get(uri);
    final body = jsonDecode(res.body) as Map<String, dynamic>;

    final status = body['status'] as String?;
    if (status != 'OK') {
      throw Exception(
        'Place details failed: $status ${body['error_message'] ?? ''}',
      );
    }

    final result = body['result'] as Map<String, dynamic>;
    final formatted = (result['formatted_address'] ?? '') as String;

    final loc =
        (((result['geometry'] as Map?)?['location'] as Map?) ?? {}) as Map;
    final lat = (loc['lat'] as num?)?.toDouble();
    final lng = (loc['lng'] as num?)?.toDouble();

    return PlaceDetailsResult(formattedAddress: formatted, lat: lat, lng: lng);
  }
}
