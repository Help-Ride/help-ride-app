import '../../../shared/services/api_client.dart';
import '../models/ride_pricing_preview.dart';

class DriverRidesApi {
  DriverRidesApi(this._client);
  final ApiClient _client;

  Future<Map<String, dynamic>> createRide({
    required String fromCity,
    required double fromLat,
    required double fromLng,
    required String toCity,
    required double toLat,
    required double toLng,
    required DateTime startTimeUtc,
    required int seatsTotal,
    required double pricePerSeat,
    String rideType = 'one-time',
    List<String> recurrenceDays = const [],
    DateTime? recurrenceEndDateUtc,
    List<DateTime> occurrenceStartTimesUtc = const [],
    DateTime? arrivalTimeUtc,
    required List<String> stops,
    required List<String> amenities,
    String? additionalNotes,
  }) async {
    final cleanedStops = stops
        .map((stop) => stop.trim())
        .where((stop) => stop.isNotEmpty)
        .toList();
    final cleanedAmenities = amenities
        .map((amenity) => amenity.trim())
        .where((amenity) => amenity.isNotEmpty)
        .toList();
    final notes = additionalNotes?.trim();
    final normalizedRecurrenceDays = recurrenceDays
        .map((day) => day.trim().toLowerCase())
        .where((day) => day.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final hasRecurringSchedule =
        rideType.trim().toLowerCase() == 'recurring' ||
        normalizedRecurrenceDays.isNotEmpty ||
        recurrenceEndDateUtc != null ||
        occurrenceStartTimesUtc.length > 1;
    final effectiveRideType = hasRecurringSchedule ? 'recurring' : 'one-time';

    final res = await _client.post<Map<String, dynamic>>(
      '/rides',
      data: {
        'fromCity': fromCity,
        'fromLat': fromLat,
        'fromLng': fromLng,
        'toCity': toCity,
        'toLat': toLat,
        'toLng': toLng,
        'startTime': startTimeUtc.toIso8601String(),
        'arrivalTime': arrivalTimeUtc?.toIso8601String(),
        'seatsTotal': seatsTotal,
        'pricePerSeat': pricePerSeat,
        'rideType': effectiveRideType,
        if (hasRecurringSchedule) 'recurrenceDays': normalizedRecurrenceDays,
        if (hasRecurringSchedule && recurrenceEndDateUtc != null)
          'recurrenceEndDate': recurrenceEndDateUtc.toIso8601String(),
        if (hasRecurringSchedule && occurrenceStartTimesUtc.isNotEmpty)
          'occurrenceStartTimes': occurrenceStartTimesUtc
              .map((value) => value.toIso8601String())
              .toList(),
        'stops': cleanedStops,
        'amenities': cleanedAmenities,
        'additionalNotes': notes?.isEmpty ?? true ? null : notes,
      },
    );
    return res.data ?? {};
  }

  Future<Map<String, dynamic>> updateRide({
    required String rideId,
    required String fromCity,
    required double fromLat,
    required double fromLng,
    required String toCity,
    required double toLat,
    required double toLng,
    required DateTime startTimeUtc,
    required int seatsTotal,
    double? pricePerSeat,
    DateTime? arrivalTimeUtc,
    required List<String> stops,
    required List<String> amenities,
    String? additionalNotes,
    String scope = 'occurrence',
  }) async {
    final id = rideId.trim();
    if (id.isEmpty) {
      throw ArgumentError('ride id can not be empty');
    }

    final cleanedStops = stops
        .map((stop) => stop.trim())
        .where((stop) => stop.isNotEmpty)
        .toList();
    final cleanedAmenities = amenities
        .map((amenity) => amenity.trim())
        .where((amenity) => amenity.isNotEmpty)
        .toList();
    final notes = additionalNotes?.trim();

    final res = await _client.put<Map<String, dynamic>>(
      '/rides/$id',
      data: {
        'fromCity': fromCity,
        'fromLat': fromLat,
        'fromLng': fromLng,
        'toCity': toCity,
        'toLat': toLat,
        'toLng': toLng,
        'startTime': startTimeUtc.toIso8601String(),
        'arrivalTime': arrivalTimeUtc?.toIso8601String(),
        if (pricePerSeat != null) 'pricePerSeat': pricePerSeat,
        'seatsTotal': seatsTotal,
        'stops': cleanedStops,
        'amenities': cleanedAmenities,
        'additionalNotes': notes?.isEmpty ?? true ? null : notes,
        'scope': scope,
      },
    );
    return res.data ?? {};
  }

  Future<Map<String, dynamic>> cancelRide(
    String rideId, {
    String scope = 'occurrence',
  }) async {
    final id = rideId.trim();
    if (id.isEmpty) {
      throw ArgumentError('ride id can not be empty');
    }
    final res = await _client.post<Map<String, dynamic>>(
      '/rides/$id/cancel',
      data: {'scope': scope},
    );
    return res.data ?? <String, dynamic>{};
  }

  Future<void> deleteRide(String rideId) async {
    final id = rideId.trim();
    if (id.isEmpty) {
      throw ArgumentError('ride id can not be empty');
    }
    await _client.delete<void>('/rides/$id');
  }

  Future<Map<String, dynamic>> startRide(String rideId) async {
    final id = rideId.trim();
    if (id.isEmpty) {
      throw ArgumentError('ride id can not be empty');
    }
    final res = await _client.put<Map<String, dynamic>>('/rides/$id/start');
    return res.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> completeRide(String rideId) async {
    final id = rideId.trim();
    if (id.isEmpty) {
      throw ArgumentError('ride id can not be empty');
    }
    final res = await _client.put<Map<String, dynamic>>('/rides/$id/complete');
    return res.data ?? <String, dynamic>{};
  }

  Future<RidePricingPreview> previewRidePricing({
    required String fromCity,
    required double fromLat,
    required double fromLng,
    required String toCity,
    required double toLat,
    required double toLng,
    required DateTime startTimeUtc,
    required int seatsTotal,
    required double pricePerSeat,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/rides/pricing-preview',
      data: {
        'fromCity': fromCity,
        'fromLat': fromLat,
        'fromLng': fromLng,
        'toCity': toCity,
        'toLat': toLat,
        'toLng': toLng,
        'startTime': startTimeUtc.toIso8601String(),
        'seatsTotal': seatsTotal,
        'pricePerSeat': pricePerSeat,
      },
    );
    return RidePricingPreview.fromJson(res.data ?? const <String, dynamic>{});
  }
}
