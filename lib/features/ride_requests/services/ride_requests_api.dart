import 'package:dio/dio.dart';
import 'dart:math' as math;

import '../../../shared/services/api_client.dart';
import '../../../shared/services/api_exception.dart';
import '../models/ride_request.dart';
import '../models/ride_request_offer.dart';

class JitIntentResponse {
  const JitIntentResponse({
    required this.clientSecret,
    required this.paymentIntentId,
    required this.amount,
    required this.currency,
    required this.quotedPricePerSeat,
    required this.requestMode,
  });

  final String clientSecret;
  final String paymentIntentId;
  final int amount;
  final String currency;
  final double quotedPricePerSeat;
  final RideRequestMode requestMode;

  factory JitIntentResponse.fromJson(Map<String, dynamic> json) {
    return JitIntentResponse(
      clientSecret: _readString(json['clientSecret'] ?? json['client_secret']),
      paymentIntentId: _readString(
        json['paymentIntentId'] ?? json['payment_intent_id'],
      ),
      amount: _readInt(json['amount']),
      currency: _readString(json['currency']).toUpperCase(),
      quotedPricePerSeat: _readDouble(
        json['quotedPricePerSeat'] ?? json['quoted_price_per_seat'],
      ),
      requestMode: rideRequestModeFromRaw(
        json['requestMode'] ?? json['request_mode'] ?? 'JIT',
      ),
    );
  }
}

class RideRequestJitRequiredException implements Exception {
  RideRequestJitRequiredException([this.message]);

  final String? message;

  @override
  String toString() {
    final text = (message ?? '').trim();
    if (text.isEmpty) {
      return 'RideRequestJitRequiredException';
    }
    return 'RideRequestJitRequiredException: $text';
  }
}

class RideRequestsApi {
  RideRequestsApi(this._client);
  final ApiClient _client;

  Future<List<RideRequest>> myRideRequests() async {
    final res = await _client.get<dynamic>('/ride-requests/me/list');
    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => RideRequest.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .whereType<Map>()
          .map((e) => RideRequest.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    if (data is Map && data['requests'] is List) {
      return (data['requests'] as List)
          .whereType<Map>()
          .map((e) => RideRequest.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    return [];
  }

  Future<RideRequest> createRideRequest({
    required String fromCity,
    required double fromLat,
    required double fromLng,
    required String toCity,
    required double toLat,
    required double toLng,
    required DateTime preferredDateUtc,
    required String preferredTime,
    String? arrivalTime,
    required int seatsNeeded,
    required String rideType,
    required String tripType,
    RideRequestMode mode = RideRequestMode.offer,
    DateTime? returnDateUtc,
    String? returnTime,
    String? jitPaymentIntentId,
    int? jitAmountCents,
    String? jitCurrency,
    num? quotedPricePerSeat,
  }) async {
    final payload = _buildRideRequestPayload(
      fromCity: fromCity,
      fromLat: fromLat,
      fromLng: fromLng,
      toCity: toCity,
      toLat: toLat,
      toLng: toLng,
      preferredDateUtc: preferredDateUtc,
      preferredTime: preferredTime,
      arrivalTime: arrivalTime,
      seatsNeeded: seatsNeeded,
      rideType: rideType,
      tripType: tripType,
      mode: mode,
      returnDateUtc: returnDateUtc,
      returnTime: returnTime,
      jitPaymentIntentId: jitPaymentIntentId,
      jitAmountCents: jitAmountCents,
      jitCurrency: jitCurrency,
      quotedPricePerSeat: quotedPricePerSeat,
    );

    dynamic data;
    try {
      final res = await _client.post<dynamic>('/ride-requests', data: payload);
      data = res.data;
    } on DioException catch (e) {
      if (mode == RideRequestMode.offer && _isJitRequiredError(e)) {
        throw RideRequestJitRequiredException(_extractErrorMessage(e));
      }
      rethrow;
    }

    if (data is Map) {
      return RideRequest.fromJson(data.cast<String, dynamic>());
    }
    return RideRequest.fromJson({});
  }

  Future<JitIntentResponse> createJitIntent({
    required String fromCity,
    required double fromLat,
    required double fromLng,
    required String toCity,
    required double toLat,
    required double toLng,
    required DateTime preferredDateUtc,
    required String preferredTime,
    String? arrivalTime,
    required int seatsNeeded,
    required String rideType,
    required String tripType,
    DateTime? returnDateUtc,
    String? returnTime,
    num? basePricePerSeat,
  }) async {
    final payload = _buildRideRequestPayload(
      fromCity: fromCity,
      fromLat: fromLat,
      fromLng: fromLng,
      toCity: toCity,
      toLat: toLat,
      toLng: toLng,
      preferredDateUtc: preferredDateUtc,
      preferredTime: preferredTime,
      arrivalTime: arrivalTime,
      seatsNeeded: seatsNeeded,
      rideType: rideType,
      tripType: tripType,
      mode: RideRequestMode.jit,
      returnDateUtc: returnDateUtc,
      returnTime: returnTime,
      basePricePerSeat: basePricePerSeat,
    );

    try {
      return await _postJitIntent(payload);
    } on DioException catch (e) {
      final shouldRetryWithFallback =
          basePricePerSeat == null && _isInvalidJitFareError(e);
      if (!shouldRetryWithFallback) rethrow;

      final fallbackBase = _fallbackBasePricePerSeat(
        fromLat: fromLat,
        fromLng: fromLng,
        toLat: toLat,
        toLng: toLng,
      );
      final retryPayload = {...payload, 'basePricePerSeat': fallbackBase};
      return _postJitIntent(retryPayload);
    }
  }

  Future<RideRequest> updateRideRequest(
    String id, {
    DateTime? preferredDateUtc,
    String? preferredTime,
    String? arrivalTime,
    int? seatsNeeded,
  }) async {
    final payload = <String, dynamic>{
      if (preferredDateUtc != null)
        'preferredDate': preferredDateUtc.toIso8601String(),
      if (preferredTime != null) 'preferredTime': preferredTime,
      if (arrivalTime != null) 'arrivalTime': arrivalTime,
      if (seatsNeeded != null) 'seatsNeeded': seatsNeeded,
    };

    final res = await _client.put<dynamic>('/ride-requests/$id', data: payload);

    final data = res.data;
    if (data is Map) {
      return RideRequest.fromJson(data.cast<String, dynamic>());
    }
    return RideRequest.fromJson({});
  }

  Future<void> deleteRideRequest(String id) async {
    await _client.delete<void>('/ride-requests/$id');
  }

  Future<List<RideRequest>> listRideRequests({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    final res = await _client.get<dynamic>(
      '/ride-requests',
      query: {
        'fromLat': fromLat,
        'fromLng': fromLng,
        'toLat': toLat,
        'toLng': toLng,
      },
    );
    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => RideRequest.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .whereType<Map>()
          .map((e) => RideRequest.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    if (data is Map && data['requests'] is List) {
      return (data['requests'] as List)
          .whereType<Map>()
          .map((e) => RideRequest.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    return [];
  }

  Future<List<RideRequest>> listRideRequestsNearby({
    required double lat,
    required double lng,
    required double radiusKm,
    int? limit,
    String? cursor,
  }) async {
    final res = await _client.get<dynamic>(
      '/ride-requests',
      query: {
        'lat': lat,
        'lng': lng,
        'radiusKm': radiusKm,
        if (limit != null) 'limit': limit,
        if (cursor != null && cursor.trim().isNotEmpty) 'cursor': cursor.trim(),
      },
    );
    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => RideRequest.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .whereType<Map>()
          .map((e) => RideRequest.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    if (data is Map && data['requests'] is List) {
      return (data['requests'] as List)
          .whereType<Map>()
          .map((e) => RideRequest.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    return [];
  }

  Future<RideRequest?> getRideRequestById(String rideRequestId) async {
    final id = rideRequestId.trim();
    if (id.isEmpty) return null;

    try {
      final res = await _client.get<dynamic>('/ride-requests/$id');
      final map = _extractMap(res.data);
      if (map == null) return null;
      return RideRequest.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<RideRequestOffer> createOffer({
    required String rideRequestId,
    required String rideId,
    required int seatsOffered,
  }) async {
    final res = await _client.post<dynamic>(
      '/ride-requests/$rideRequestId/offers',
      data: {'rideId': rideId, 'seatsOffered': seatsOffered},
    );
    final data = res.data;
    if (data is Map) {
      return RideRequestOffer.fromJson(data.cast<String, dynamic>());
    }
    return RideRequestOffer.fromJson({});
  }

  Future<List<RideRequestOffer>> myOffers() async {
    final res = await _client.get<dynamic>('/ride-requests/offers/me/list');
    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => RideRequestOffer.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .whereType<Map>()
          .map((e) => RideRequestOffer.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    return [];
  }

  Future<void> cancelOffer({
    required String rideRequestId,
    required String offerId,
  }) async {
    await _client.put<void>(
      '/ride-requests/$rideRequestId/offers/$offerId/cancel',
    );
  }

  Future<List<RideRequestOffer>> listOffers(String rideRequestId) async {
    final res = await _client.get<dynamic>(
      '/ride-requests/$rideRequestId/offers',
    );
    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => RideRequestOffer.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .whereType<Map>()
          .map((e) => RideRequestOffer.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    return [];
  }

  Future<void> acceptOffer({
    required String rideRequestId,
    required String offerId,
  }) async {
    await _client.put<void>(
      '/ride-requests/$rideRequestId/offers/$offerId/accept',
    );
  }

  Future<void> rejectOffer({
    required String rideRequestId,
    required String offerId,
  }) async {
    await _client.put<void>(
      '/ride-requests/$rideRequestId/offers/$offerId/reject',
    );
  }

  Map<String, dynamic>? _extractMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      final casted = data.cast<String, dynamic>();
      final nestedData = casted['data'];
      if (nestedData is Map<String, dynamic>) return nestedData;
      if (nestedData is Map) return nestedData.cast<String, dynamic>();
      final request = casted['request'];
      if (request is Map<String, dynamic>) return request;
      if (request is Map) return request.cast<String, dynamic>();
      return casted;
    }
    return null;
  }

  Map<String, dynamic> _buildRideRequestPayload({
    required String fromCity,
    required double fromLat,
    required double fromLng,
    required String toCity,
    required double toLat,
    required double toLng,
    required DateTime preferredDateUtc,
    required String preferredTime,
    String? arrivalTime,
    required int seatsNeeded,
    required String rideType,
    required String tripType,
    RideRequestMode mode = RideRequestMode.offer,
    DateTime? returnDateUtc,
    String? returnTime,
    String? jitPaymentIntentId,
    int? jitAmountCents,
    String? jitCurrency,
    num? quotedPricePerSeat,
    num? basePricePerSeat,
  }) {
    return {
      'fromCity': fromCity,
      'fromLat': fromLat,
      'fromLng': fromLng,
      'toCity': toCity,
      'toLat': toLat,
      'toLng': toLng,
      'preferredDate': preferredDateUtc.toIso8601String(),
      'preferredTime': preferredTime,
      if (arrivalTime != null && arrivalTime.isNotEmpty)
        'arrivalTime': arrivalTime,
      'seatsNeeded': seatsNeeded,
      'rideType': rideType,
      'tripType': tripType,
      'mode': rideRequestModeToWire(mode),
      if (returnDateUtc != null) 'returnDate': returnDateUtc.toIso8601String(),
      if (returnTime != null && returnTime.isNotEmpty) 'returnTime': returnTime,
      if (jitPaymentIntentId != null && jitPaymentIntentId.trim().isNotEmpty)
        'jitPaymentIntentId': jitPaymentIntentId.trim(),
      if (jitAmountCents != null) 'jitAmountCents': jitAmountCents,
      if (jitCurrency != null && jitCurrency.trim().isNotEmpty)
        'jitCurrency': jitCurrency.trim().toUpperCase(),
      if (quotedPricePerSeat != null) 'quotedPricePerSeat': quotedPricePerSeat,
      if (basePricePerSeat != null) 'basePricePerSeat': basePricePerSeat,
    };
  }

  bool _isJitRequiredError(DioException e) {
    final message = _extractErrorMessage(e).toLowerCase();
    if (message.isEmpty) return false;
    return message.contains('/ride-requests/jit/intent') ||
        (message.contains('within 2 hours') && message.contains('use post'));
  }

  String _extractErrorMessage(DioException e) {
    final err = e.error;
    if (err is ApiException) {
      return err.message;
    }
    final data = e.response?.data;
    if (data is Map) {
      final message = (data['error'] ?? data['message'] ?? '')
          .toString()
          .trim();
      if (message.isNotEmpty) return message;
    }
    return err?.toString() ?? e.toString();
  }

  bool _isInvalidJitFareError(DioException e) {
    final message = _extractErrorMessage(e).toLowerCase();
    if (message.isEmpty) return false;
    return message.contains('invalid jit fare amount') ||
        message.contains('invalid fare amount');
  }

  Future<JitIntentResponse> _postJitIntent(Map<String, dynamic> payload) async {
    final res = await _client.post<dynamic>(
      '/ride-requests/jit/intent',
      data: payload,
    );
    final map = _extractMap(res.data) ?? const <String, dynamic>{};
    final parsed = JitIntentResponse.fromJson(map);
    if (parsed.clientSecret.isEmpty || parsed.paymentIntentId.isEmpty) {
      throw Exception('Invalid JIT payment intent response.');
    }
    return parsed;
  }

  double _fallbackBasePricePerSeat({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    final distanceKm = _distanceKm(
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
    );
    final distanceBased = distanceKm * 0.45;
    final bounded = distanceBased.clamp(5.0, 120.0);
    return double.parse(bounded.toStringAsFixed(2));
  }

  double _distanceKm({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(toLat - fromLat);
    final dLng = _degToRad(toLng - fromLng);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(_degToRad(fromLat)) *
            math.cos(_degToRad(toLat)) *
            math.pow(math.sin(dLng / 2), 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);
}

String _readString(dynamic value) {
  final parsed = value?.toString().trim();
  if (parsed == null || parsed.isEmpty) return '';
  return parsed;
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _readDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
