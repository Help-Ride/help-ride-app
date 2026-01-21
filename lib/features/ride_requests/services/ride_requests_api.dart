import '../../../shared/services/api_client.dart';
import '../models/ride_request.dart';
import '../models/ride_request_offer.dart';

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
  }) async {
    final res = await _client.post<dynamic>(
      '/ride-requests',
      data: {
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
      },
    );

    final data = res.data;
    if (data is Map) {
      return RideRequest.fromJson(data.cast<String, dynamic>());
    }
    return RideRequest.fromJson({});
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

    final res = await _client.put<dynamic>(
      '/ride-requests/$id',
      data: payload,
    );

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
    required String fromCity,
    required String toCity,
  }) async {
    final res = await _client.get<dynamic>(
      '/ride-requests',
      query: {
        'fromCity': fromCity,
        'toCity': toCity,
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
    return [];
  }

  Future<RideRequestOffer> createOffer({
    required String rideRequestId,
    required String rideId,
    required int seatsOffered,
  }) async {
    final res = await _client.post<dynamic>(
      '/ride-requests/$rideRequestId/offers',
      data: {
        'rideId': rideId,
        'seatsOffered': seatsOffered,
      },
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
    final res =
        await _client.get<dynamic>('/ride-requests/$rideRequestId/offers');
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
}
