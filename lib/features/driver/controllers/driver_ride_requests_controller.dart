import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/services/api_client.dart';
import '../../../shared/widgets/place_picker_field.dart';
import '../../ride_requests/models/ride_request.dart';
import '../../ride_requests/models/ride_request_offer.dart';
import '../../ride_requests/services/ride_requests_api.dart';

enum DriverRideRequestsTab { requests, offers }

class DriverRideItemLite {
  final String id;
  final String from;
  final String to;
  final double? fromLat;
  final double? fromLng;
  final double? toLat;
  final double? toLng;
  final DateTime startTime;
  final int seatsAvailable;
  final double pricePerSeat;

  DriverRideItemLite({
    required this.id,
    required this.from,
    required this.to,
    this.fromLat,
    this.fromLng,
    this.toLat,
    this.toLng,
    required this.startTime,
    required this.seatsAvailable,
    required this.pricePerSeat,
  });
}

class DriverRideRequestsController extends GetxController {
  late final ApiClient _client;
  late final RideRequestsApi _api;

  final tab = DriverRideRequestsTab.requests.obs;

  final fromCtrl = TextEditingController();
  final toCtrl = TextEditingController();
  final fromPick = Rxn<PlacePick>();
  final toPick = Rxn<PlacePick>();

  final requestsLoading = false.obs;
  final requestsError = RxnString();
  final requests = <RideRequest>[].obs;

  final offersLoading = false.obs;
  final offersError = RxnString();
  final offers = <RideRequestOffer>[].obs;
  final cancelingOfferIds = <String>{}.obs;

  final ridesLoading = false.obs;
  final driverRides = <DriverRideItemLite>[].obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    _client = await ApiClient.create();
    _api = RideRequestsApi(_client);
    await fetchOffers();
  }

  @override
  void onClose() {
    fromCtrl.dispose();
    toCtrl.dispose();
    super.onClose();
  }

  void setTab(DriverRideRequestsTab t) => tab.value = t;

  Future<void> searchRequests() async {
    final from = (fromPick.value?.fullText ?? fromCtrl.text).trim();
    final to = (toPick.value?.fullText ?? toCtrl.text).trim();
    if (from.isEmpty || to.isEmpty) {
      requestsError.value = 'Enter both from/to cities.';
      return;
    }

    final fromLat = fromPick.value?.latLng?.lat;
    final fromLng = fromPick.value?.latLng?.lng;
    final toLat = toPick.value?.latLng?.lat;
    final toLng = toPick.value?.latLng?.lng;
    if (fromLat == null || fromLng == null || toLat == null || toLng == null) {
      requestsError.value =
          'Select locations from suggestions to include coordinates.';
      return;
    }

    requestsLoading.value = true;
    requestsError.value = null;
    try {
      final list = await _api.listRideRequests(
        fromLat: fromLat,
        fromLng: fromLng,
        toLat: toLat,
        toLng: toLng,
      );
      list.sort(
        (a, b) => _requestSortTime(b).compareTo(_requestSortTime(a)),
      );
      requests.assignAll(list);
    } catch (e) {
      requestsError.value = e.toString();
    } finally {
      requestsLoading.value = false;
    }
  }

  Future<void> fetchOffers() async {
    offersLoading.value = true;
    offersError.value = null;
    try {
      final list = await _api.myOffers();
      offers.assignAll(list);
    } catch (e) {
      offersError.value = e.toString();
    } finally {
      offersLoading.value = false;
    }
  }

  DateTime _requestSortTime(RideRequest request) {
    return request.updatedAt ?? request.createdAt;
  }

  Future<void> loadDriverRides() async {
    if (ridesLoading.value) return;
    ridesLoading.value = true;
    try {
      final res = await _client.get<dynamic>('/rides/me/list');
      final raw = res.data;
      if (raw is! List) {
        driverRides.clear();
        return;
      }
      final parsed = raw
          .whereType<Map>()
          .map((m) => _mapRide(m.cast<String, dynamic>()))
          .toList();
      driverRides.assignAll(parsed);
    } finally {
      ridesLoading.value = false;
    }
  }

  DriverRideItemLite _mapRide(Map<String, dynamic> j) {
    double toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0;
    }

    int toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    DateTime toDate(dynamic v) {
      final s = (v ?? '').toString();
      final dt = DateTime.tryParse(s);
      return (dt ?? DateTime.now()).toLocal();
    }

    return DriverRideItemLite(
      id: (j['id'] ?? '').toString(),
      from: (j['fromCity'] ?? '').toString(),
      to: (j['toCity'] ?? '').toString(),
      fromLat: toDouble(j['fromLat']),
      fromLng: toDouble(j['fromLng']),
      toLat: toDouble(j['toLat']),
      toLng: toDouble(j['toLng']),
      startTime: toDate(j['startTime']),
      seatsAvailable: toInt(j['seatsAvailable']),
      pricePerSeat: toDouble(j['pricePerSeat']),
    );
  }

  List<DriverRideItemLite> matchingRidesFor(RideRequest request) {
    final reqFromLat = request.fromLat;
    final reqFromLng = request.fromLng;
    final reqToLat = request.toLat;
    final reqToLng = request.toLng;
    if (reqFromLat == null ||
        reqFromLng == null ||
        reqToLat == null ||
        reqToLng == null) {
      return [];
    }

    const maxDistanceKm = 10.0;
    final now = DateTime.now();

    return driverRides.where((ride) {
      if (!ride.startTime.isAfter(now)) return false;
      if (ride.seatsAvailable <= 0) return false;
      if (ride.fromLat == null ||
          ride.fromLng == null ||
          ride.toLat == null ||
          ride.toLng == null) {
        return false;
      }
      final pickupKm = _distanceKm(
        reqFromLat,
        reqFromLng,
        ride.fromLat!,
        ride.fromLng!,
      );
      final dropoffKm = _distanceKm(
        reqToLat,
        reqToLng,
        ride.toLat!,
        ride.toLng!,
      );
      return pickupKm <= maxDistanceKm && dropoffKm <= maxDistanceKm;
    }).toList();
  }

  double _distanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = pow(sin(dLat / 2), 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            pow(sin(dLon / 2), 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degToRad(double deg) => deg * (pi / 180.0);

  Future<void> createOffer({
    required String rideRequestId,
    required String rideId,
    required int seatsOffered,
  }) async {
    await _api.createOffer(
      rideRequestId: rideRequestId,
      rideId: rideId,
      seatsOffered: seatsOffered,
    );
    await fetchOffers();
  }

  Future<void> cancelOffer({
    required String rideRequestId,
    required String offerId,
  }) async {
    if (cancelingOfferIds.contains(offerId)) return;
    cancelingOfferIds.add(offerId);
    cancelingOfferIds.refresh();
    try {
      await _api.cancelOffer(rideRequestId: rideRequestId, offerId: offerId);
      offers.removeWhere((o) => o.id == offerId);
      Get.snackbar('Cancelled', 'Offer cancelled.');
    } catch (e) {
      Get.snackbar('Failed', e.toString());
    } finally {
      cancelingOfferIds.remove(offerId);
      cancelingOfferIds.refresh();
    }
  }
}
