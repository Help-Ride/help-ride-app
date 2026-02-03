import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../shared/controllers/session_controller.dart';
import '../../../shared/services/api_client.dart';
import '../../../shared/services/push_notification_service.dart';
import '../../../shared/services/token_storage.dart';
import '../../ride_requests/models/ride_request.dart';
import '../../ride_requests/services/ride_requests_api.dart';
import '../routes/driver_routes.dart';
import '../widgets/ride_offer_dialog.dart';

class DriverRideOffer {
  static const String fallbackPickupAddress = 'Pickup location';
  static const String fallbackDropoffAddress = 'Dropoff location';

  const DriverRideOffer({
    required this.rideRequestId,
    required this.pickupAddress,
    required this.dropoffAddress,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    required this.raw,
  });

  final String rideRequestId;
  final String pickupAddress;
  final String dropoffAddress;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;
  final Map<String, dynamic> raw;

  factory DriverRideOffer.fromPayload(dynamic payload) {
    final map = _asMap(payload);
    final data = _asMap(map['data']);
    final request = _firstNonEmptyMap([
      _asMap(map['rideRequest']),
      _asMap(map['ride_request']),
      _asMap(map['request']),
      _asMap(data['rideRequest']),
      _asMap(data['ride_request']),
      _asMap(data['request']),
    ]);
    final booking = _firstNonEmptyMap([
      _asMap(map['booking']),
      _asMap(data['booking']),
    ]);
    final sources = [map, data, request, booking];

    final rideRequestId =
        _readFirstString(
          maps: [map, data, booking],
          keys: const [
            'rideRequestId',
            'ride_request_id',
            'requestId',
            'request_id',
          ],
        ) ??
        _readFirstString(
          maps: [request],
          keys: const ['id', 'rideRequestId', 'ride_request_id'],
        ) ??
        '';

    final pickup =
        _readFirstAddress(
          maps: sources,
          keys: const [
            'pickupAddress',
            'pickup_address',
            'pickupLocation',
            'pickup_location',
            'passengerPickupName',
            'passenger_pickup_name',
            'pickup',
            'fromAddress',
            'from_address',
            'fromCity',
            'from_city',
            'from',
            'originAddress',
            'origin_address',
            'origin',
          ],
        ) ??
        fallbackPickupAddress;

    final dropoff =
        _readFirstAddress(
          maps: sources,
          keys: const [
            'dropoffAddress',
            'dropoff_address',
            'dropoffLocation',
            'dropoff_location',
            'passengerDropoffName',
            'passenger_dropoff_name',
            'dropoff',
            'toAddress',
            'to_address',
            'toCity',
            'to_city',
            'to',
            'destinationAddress',
            'destination_address',
            'destination',
          ],
        ) ??
        fallbackDropoffAddress;

    final pickupLat = _readFirstDouble(
      maps: sources,
      isLatitude: true,
      keys: const [
        'passengerPickupLat',
        'passenger_pickup_lat',
        'pickupLat',
        'pickup_lat',
        'pickupLocation',
        'pickup_location',
        'pickup',
        'fromLat',
        'from_lat',
        'from',
        'originLat',
        'origin_lat',
        'origin',
      ],
    );
    final pickupLng = _readFirstDouble(
      maps: sources,
      isLatitude: false,
      keys: const [
        'passengerPickupLng',
        'passenger_pickup_lng',
        'pickupLng',
        'pickup_lng',
        'pickupLocation',
        'pickup_location',
        'pickup',
        'fromLng',
        'from_lng',
        'from',
        'originLng',
        'origin_lng',
        'origin',
      ],
    );
    final dropoffLat = _readFirstDouble(
      maps: sources,
      isLatitude: true,
      keys: const [
        'passengerDropoffLat',
        'passenger_dropoff_lat',
        'dropoffLat',
        'dropoff_lat',
        'dropoffLocation',
        'dropoff_location',
        'dropoff',
        'toLat',
        'to_lat',
        'to',
        'destinationLat',
        'destination_lat',
        'destination',
      ],
    );
    final dropoffLng = _readFirstDouble(
      maps: sources,
      isLatitude: false,
      keys: const [
        'passengerDropoffLng',
        'passenger_dropoff_lng',
        'dropoffLng',
        'dropoff_lng',
        'dropoffLocation',
        'dropoff_location',
        'dropoff',
        'toLng',
        'to_lng',
        'to',
        'destinationLng',
        'destination_lng',
        'destination',
      ],
    );

    return DriverRideOffer(
      rideRequestId: rideRequestId,
      pickupAddress: pickup,
      dropoffAddress: dropoff,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropoffLat: dropoffLat,
      dropoffLng: dropoffLng,
      raw: map,
    );
  }

  factory DriverRideOffer.fromRideRequest(RideRequest request) {
    final pickup = request.fromCity.trim();
    final dropoff = request.toCity.trim();

    return DriverRideOffer(
      rideRequestId: request.id,
      pickupAddress: pickup.isEmpty ? fallbackPickupAddress : pickup,
      dropoffAddress: dropoff.isEmpty ? fallbackDropoffAddress : dropoff,
      pickupLat: request.fromLat,
      pickupLng: request.fromLng,
      dropoffLat: request.toLat,
      dropoffLng: request.toLng,
      raw: {
        'rideRequestId': request.id,
        'fromCity': request.fromCity,
        'toCity': request.toCity,
        'fromLat': request.fromLat,
        'fromLng': request.fromLng,
        'toLat': request.toLat,
        'toLng': request.toLng,
      },
    );
  }
}

class DriverRealtimeController extends GetxController
    with WidgetsBindingObserver {
  static const Duration _locationInterval = Duration(seconds: 4);
  static const int _offerCountdownSeconds = 15;

  final isOnline = false.obs;
  final isConnecting = false.obs;
  final isReconnecting = false.obs;
  final socketConnected = false.obs;
  final isStreamingLocation = false.obs;

  final lastPosition = Rxn<Position>();
  final locationError = RxnString();

  final activeOffer = Rxn<DriverRideOffer>();
  final offerSecondsRemaining = 0.obs;
  final offerActionLoading = false.obs;

  late final TokenStorage _tokenStorage;
  late final SessionController _session;
  late final RideRequestsApi _rideRequestsApi;

  io.Socket? _socket;
  Timer? _locationTimer;
  Timer? _offerTimer;
  Timer? _acceptTimeoutTimer;

  Worker? _sessionWorker;
  StreamSubscription<String>? _pushRideOfferSub;

  bool _isForeground = true;
  bool _offerDialogOpen = false;
  bool _locationPromptOpen = false;

  @override
  Future<void> onInit() async {
    super.onInit();
    _tokenStorage = TokenStorage();
    _session = Get.find<SessionController>();
    final client = await ApiClient.create();
    _rideRequestsApi = RideRequestsApi(client);

    WidgetsBinding.instance.addObserver(this);

    _sessionWorker = ever<SessionStatus>(_session.status, (status) {
      if (status != SessionStatus.authenticated) {
        _forceOfflineAndDisconnect();
        return;
      }

      if (_session.isDriver) {
        unawaited(_connectSocket());
      }
    });

    _pushRideOfferSub = PushNotificationService.instance.rideOfferStream.listen(
      _onPushRideOfferRequested,
    );

    if (_session.status.value == SessionStatus.authenticated &&
        _session.isDriver) {
      unawaited(_connectSocket());
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionWorker?.dispose();
    _pushRideOfferSub?.cancel();
    _stopLocationLoop();
    _stopOfferTimer();
    _acceptTimeoutTimer?.cancel();
    _disconnectSocket();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isForeground = true;
      unawaited(_handleAppResumed());
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _isForeground = false;
      _stopLocationLoop();
      if (isOnline.value && socketConnected.value) {
        _socket?.emit('driver:appState', {'background': true});
      }
    }
  }

  Future<void> setOnline(bool value) async {
    if (value) {
      await goOnline();
    } else {
      await goOffline();
    }
  }

  Future<void> goOnline() async {
    if (isConnecting.value) return;
    isConnecting.value = true;
    locationError.value = null;

    try {
      final ready = await _ensureLocationReady(requestPermission: true);
      if (!ready) {
        isOnline.value = false;
        return;
      }

      final position = await _getCurrentPosition();
      if (position == null) {
        isOnline.value = false;
        return;
      }

      lastPosition.value = position;
      isOnline.value = true;
      await _connectSocket();
      _emitDriverOnline(position);
      if (_isForeground) _startLocationLoop();
    } finally {
      isConnecting.value = false;
    }
  }

  Future<void> goOffline() async {
    if (isConnecting.value && !isOnline.value) return;
    _stopLocationLoop();
    _stopOfferTimer();
    _acceptTimeoutTimer?.cancel();
    offerActionLoading.value = false;
    activeOffer.value = null;
    offerSecondsRemaining.value = 0;
    if (_offerDialogOpen && (Get.isDialogOpen ?? false)) {
      Get.back();
    }

    if (_socket?.connected == true) {
      _socket?.emit('driver:offline');
    }
    _disconnectSocket();

    isOnline.value = false;
    isReconnecting.value = false;
    socketConnected.value = false;
  }

  Future<void> acceptActiveOffer() async {
    final offer = activeOffer.value;
    if (offer == null || offerActionLoading.value) return;

    _traceRealtime('accept_tap rideRequestId=${offer.rideRequestId}');
    offerActionLoading.value = true;
    await _connectSocket();

    _traceRealtime('emit ride:accept rideRequestId=${offer.rideRequestId}');
    _socket?.emit('ride:accept', {'rideRequestId': offer.rideRequestId});

    _acceptTimeoutTimer?.cancel();
    _acceptTimeoutTimer = Timer(const Duration(seconds: 10), () {
      if (!offerActionLoading.value) return;
      _traceRealtime('accept_timeout rideRequestId=${offer.rideRequestId}');
      offerActionLoading.value = false;
      Get.snackbar('Still waiting', 'No confirmation yet. Please try again.');
    });
  }

  Future<void> rejectActiveOffer() async {
    final offer = activeOffer.value;
    if (offer == null) return;
    _socket?.emit('ride:reject', {'rideRequestId': offer.rideRequestId});
    _clearOffer(closeDialog: true);
  }

  Future<void> _handleAppResumed() async {
    if (!isOnline.value) return;
    await _ensureLocationReady(requestPermission: false);
    final position = await _getCurrentPosition();
    if (position != null) {
      lastPosition.value = position;
    }
    await _connectSocket();
    final latest = lastPosition.value;
    if (latest != null) {
      _emitDriverOnline(latest);
    }
    _startLocationLoop();
  }

  Future<void> _connectSocket() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Missing access token for realtime connection.');
    }

    if (_socket?.connected == true) return;
    if (_socket != null && _socket!.disconnected) {
      _socket!.connect();
      return;
    }

    final url = _resolveSocketUrl();
    _socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token.trim()})
          .enableReconnection()
          .setReconnectionAttempts(1000000)
          .setReconnectionDelay(1200)
          .setReconnectionDelayMax(5000)
          .enableForceNew()
          .disableAutoConnect()
          .build(),
    );

    _wireSocketListeners(_socket!);
    isReconnecting.value = true;
    _socket!.connect();
  }

  void _disconnectSocket() {
    final socket = _socket;
    if (socket == null) return;
    try {
      socket.clearListeners();
      socket.dispose();
      socket.disconnect();
    } catch (_) {
      // ignore dispose errors
    }
    _socket = null;
  }

  void _wireSocketListeners(io.Socket socket) {
    socket.onConnect((_) {
      socketConnected.value = true;
      isReconnecting.value = false;
      _traceRealtime('socket_connected');
      if (isOnline.value) {
        final position = lastPosition.value;
        if (position != null) _emitDriverOnline(position);
      }
    });

    socket.onDisconnect((_) {
      socketConnected.value = false;
      _traceRealtime('socket_disconnected');
      if (isOnline.value) {
        isReconnecting.value = true;
      }
    });

    socket.onConnectError((_) {
      socketConnected.value = false;
      _traceRealtime('socket_connect_error');
      if (isOnline.value) isReconnecting.value = true;
    });

    socket.onError((_) {
      socketConnected.value = false;
      _traceRealtime('socket_error');
      if (isOnline.value) isReconnecting.value = true;
    });

    socket.on('reconnect_attempt', (_) {
      if (isOnline.value) isReconnecting.value = true;
    });

    socket.on('reconnect', (_) {
      socketConnected.value = true;
      isReconnecting.value = false;
      if (isOnline.value) {
        final position = lastPosition.value;
        if (position != null) _emitDriverOnline(position);
      }
    });

    socket.on('ride:offer', _onRideOfferEvent);
    socket.on('ride:cancelled', _onRideCancelledEvent);
    socket.on('ride:accept_result', _onRideAcceptResultEvent);
  }

  void _emitDriverOnline(Position position) {
    _socket?.emit('driver:online', {
      'lat': position.latitude,
      'lng': position.longitude,
    });
  }

  void _emitDriverLocation(Position position) {
    _socket?.emit('driver:location', {
      'lat': position.latitude,
      'lng': position.longitude,
    });
  }

  void _startLocationLoop() {
    if (_locationTimer != null || !isOnline.value) return;
    isStreamingLocation.value = true;
    _locationTimer = Timer.periodic(_locationInterval, (_) async {
      if (!_isForeground || !isOnline.value) return;

      final ready = await _ensureLocationReady(requestPermission: false);
      if (!ready) {
        await _handleLocationUnavailable();
        return;
      }

      final position = await _getCurrentPosition();
      if (position == null) return;
      lastPosition.value = position;

      if (_socket?.connected != true) {
        isReconnecting.value = true;
        await _connectSocket();
      }
      _emitDriverLocation(position);
    });
  }

  void _stopLocationLoop() {
    _locationTimer?.cancel();
    _locationTimer = null;
    isStreamingLocation.value = false;
  }

  Future<bool> _ensureLocationReady({required bool requestPermission}) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      locationError.value = 'Location services are disabled.';
      if (requestPermission) {
        _showLocationBlockedDialog(
          title: 'Enable Location Services',
          message:
              'Location is required to go online. Turn on location services.',
          actionText: 'Open Settings',
          action: Geolocator.openLocationSettings,
        );
      }
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && requestPermission) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      locationError.value = 'Location permission denied.';
      if (requestPermission) {
        _showLocationBlockedDialog(
          title: 'Location Permission Needed',
          message:
              'Allow location permission to receive and accept nearby rides.',
          actionText: 'Try Again',
          action: () async {
            await Geolocator.requestPermission();
          },
        );
      }
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      locationError.value = 'Location permission permanently denied.';
      if (requestPermission) {
        _showLocationBlockedDialog(
          title: 'Location Permission Blocked',
          message: 'Open app settings and allow location to go online.',
          actionText: 'Open App Settings',
          action: Geolocator.openAppSettings,
        );
      }
      return false;
    }

    locationError.value = null;
    return true;
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return position;
    } catch (e) {
      locationError.value = e.toString();
      return null;
    }
  }

  Future<void> _handleLocationUnavailable() async {
    if (!isOnline.value) return;
    await goOffline();
    _showLocationBlockedDialog(
      title: 'You are offline',
      message:
          'Location access is required to stay online. Re-enable location and go online again.',
      actionText: 'Open Settings',
      action: Geolocator.openAppSettings,
    );
  }

  void _showLocationBlockedDialog({
    required String title,
    required String message,
    required String actionText,
    required Future<void> Function() action,
  }) {
    if (_locationPromptOpen) return;
    _locationPromptOpen = true;

    Get.dialog<void>(
      PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () async {
                await action();
                if (Get.isDialogOpen ?? false) {
                  Get.back();
                }
              },
              child: Text(actionText),
            ),
            TextButton(
              onPressed: () {
                if (Get.isDialogOpen ?? false) {
                  Get.back();
                }
              },
              child: const Text('Close'),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    ).whenComplete(() {
      _locationPromptOpen = false;
    });
  }

  void _onRideOfferEvent(dynamic payload) {
    final map = _asMap(payload);
    final id =
        _readString(map['rideRequestId']) ??
        _readString(map['ride_request_id']) ??
        _readString(_asMap(map['rideRequest'])['id']) ??
        '';
    _traceRealtime('event ride:offer rideRequestId=$id');
    unawaited(_handleRideOfferEvent(payload));
  }

  Future<void> _handleRideOfferEvent(dynamic payload) async {
    final offer = DriverRideOffer.fromPayload(payload);
    if (offer.rideRequestId.trim().isEmpty) return;
    if (activeOffer.value != null) return;

    final hydratedOffer = await _hydrateOfferIfNeeded(offer);
    if (activeOffer.value != null) return;
    _showOffer(hydratedOffer);
  }

  void _onRideCancelledEvent(dynamic payload) {
    final map = _asMap(payload);
    final rideRequestId =
        _readString(map['rideRequestId']) ??
        _readString(map['ride_request_id']) ??
        _readString(_asMap(map['rideRequest'])['id']) ??
        '';

    _traceRealtime('event ride:cancelled rideRequestId=$rideRequestId');
    final current = activeOffer.value;
    if (current == null) return;
    if (rideRequestId.isNotEmpty && current.rideRequestId != rideRequestId) {
      return;
    }

    _clearOffer(closeDialog: true);
    Get.snackbar('Offer expired', 'Offer expired / taken');
  }

  void _onRideAcceptResultEvent(dynamic payload) {
    final map = _asMap(payload);
    final current = activeOffer.value;
    if (current == null) return;

    final rideRequestId =
        _readString(map['rideRequestId']) ??
        _readString(map['ride_request_id']) ??
        _readString(_asMap(map['rideRequest'])['id']) ??
        '';
    final ok = _readBool(map['ok']) || _looksAcceptedStatus(map);
    final status =
        _readString(map['status']) ?? _readString(map['result']) ?? '';
    final reasonPreview =
        (_readString(map['reason']) ??
                _readString(map['error']) ??
                _readString(map['message']) ??
                '')
            .trim();
    _traceRealtime(
      'event ride:accept_result rideRequestId=$rideRequestId ok=$ok status=$status reason=$reasonPreview',
    );

    if (rideRequestId.isNotEmpty && rideRequestId != current.rideRequestId) {
      return;
    }

    _acceptTimeoutTimer?.cancel();
    offerActionLoading.value = false;

    final reason =
        (_readString(map['reason']) ??
                _readString(map['error']) ??
                _readString(map['message']) ??
                '')
            .trim()
            .toLowerCase();

    if (ok) {
      final acceptedOffer = current;
      _clearOffer(closeDialog: true);
      Get.toNamed(
        DriverRoutes.activeRide,
        arguments: {
          'rideRequestId': acceptedOffer.rideRequestId,
          'pickupAddress': acceptedOffer.pickupAddress,
          'dropoffAddress': acceptedOffer.dropoffAddress,
          'pickupLat': acceptedOffer.pickupLat,
          'pickupLng': acceptedOffer.pickupLng,
          'dropoffLat': acceptedOffer.dropoffLat,
          'dropoffLng': acceptedOffer.dropoffLng,
          'result': map,
        },
      );
      return;
    }

    _clearOffer(closeDialog: true);
    if (reason.contains('already_taken') || reason.contains('already taken')) {
      Get.snackbar('Offer unavailable', 'This offer was already taken.');
      return;
    }

    Get.snackbar(
      'Could not accept',
      reason.isEmpty ? 'Offer could not be accepted.' : reason,
    );
  }

  Future<void> _onPushRideOfferRequested(String rideRequestId) async {
    final id = rideRequestId.trim();
    if (id.isEmpty) return;
    if (activeOffer.value != null) return;

    _traceRealtime('push_offer rideRequestId=$id');
    await _connectSocket();

    DriverRideOffer offer;
    final request = await _rideRequestsApi.getRideRequestById(id);
    if (request != null) {
      offer = DriverRideOffer.fromRideRequest(request);
    } else {
      offer = DriverRideOffer(
        rideRequestId: id,
        pickupAddress: DriverRideOffer.fallbackPickupAddress,
        dropoffAddress: DriverRideOffer.fallbackDropoffAddress,
        pickupLat: null,
        pickupLng: null,
        dropoffLat: null,
        dropoffLng: null,
        raw: {'rideRequestId': id},
      );
    }
    _showOffer(offer);
  }

  Future<DriverRideOffer> _hydrateOfferIfNeeded(DriverRideOffer offer) async {
    final pickup = offer.pickupAddress.trim().toLowerCase();
    final dropoff = offer.dropoffAddress.trim().toLowerCase();
    final pickupMissing =
        pickup.isEmpty ||
        pickup == DriverRideOffer.fallbackPickupAddress.toLowerCase();
    final dropoffMissing =
        dropoff.isEmpty ||
        dropoff == DriverRideOffer.fallbackDropoffAddress.toLowerCase();
    final pickupCoordsMissing =
        offer.pickupLat == null || offer.pickupLng == null;
    final dropoffCoordsMissing =
        offer.dropoffLat == null || offer.dropoffLng == null;

    if (!pickupMissing &&
        !dropoffMissing &&
        !pickupCoordsMissing &&
        !dropoffCoordsMissing) {
      return offer;
    }

    final request = await _rideRequestsApi.getRideRequestById(
      offer.rideRequestId,
    );
    if (request == null) return offer;
    final fromRequest = DriverRideOffer.fromRideRequest(request);

    return DriverRideOffer(
      rideRequestId: offer.rideRequestId,
      pickupAddress: pickupMissing
          ? fromRequest.pickupAddress
          : offer.pickupAddress,
      dropoffAddress: dropoffMissing
          ? fromRequest.dropoffAddress
          : offer.dropoffAddress,
      pickupLat: pickupCoordsMissing ? fromRequest.pickupLat : offer.pickupLat,
      pickupLng: pickupCoordsMissing ? fromRequest.pickupLng : offer.pickupLng,
      dropoffLat: dropoffCoordsMissing
          ? fromRequest.dropoffLat
          : offer.dropoffLat,
      dropoffLng: dropoffCoordsMissing
          ? fromRequest.dropoffLng
          : offer.dropoffLng,
      raw: {...offer.raw, ...fromRequest.raw},
    );
  }

  void _showOffer(DriverRideOffer offer) {
    _traceRealtime('show_offer rideRequestId=${offer.rideRequestId}');
    activeOffer.value = offer;
    offerActionLoading.value = false;
    offerSecondsRemaining.value = _offerCountdownSeconds;
    _startOfferTimer();
    _showOfferDialog(offer);
  }

  void _showOfferDialog(DriverRideOffer offer) {
    if (_offerDialogOpen) return;
    _offerDialogOpen = true;

    Get.dialog<void>(
      RideOfferDialog(
        offer: offer,
        countdown: offerSecondsRemaining,
        isProcessing: offerActionLoading,
        onAccept: acceptActiveOffer,
        onReject: rejectActiveOffer,
      ),
      barrierDismissible: false,
      useSafeArea: true,
    ).whenComplete(() {
      _offerDialogOpen = false;
    });
  }

  void _startOfferTimer() {
    _stopOfferTimer();
    _offerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = offerSecondsRemaining.value - 1;
      offerSecondsRemaining.value = remaining;
      if (remaining > 0) return;
      timer.cancel();
      _clearOffer(closeDialog: true);
      Get.snackbar('Offer expired', 'Offer expired / taken');
    });
  }

  void _stopOfferTimer() {
    _offerTimer?.cancel();
    _offerTimer = null;
  }

  void _clearOffer({required bool closeDialog}) {
    final id = activeOffer.value?.rideRequestId ?? '';
    if (id.isNotEmpty) {
      _traceRealtime('clear_offer rideRequestId=$id');
    }
    _stopOfferTimer();
    _acceptTimeoutTimer?.cancel();
    offerActionLoading.value = false;
    offerSecondsRemaining.value = 0;
    activeOffer.value = null;

    if (closeDialog && _offerDialogOpen && (Get.isDialogOpen ?? false)) {
      Get.back();
    }
  }

  Future<void> _forceOfflineAndDisconnect() async {
    _stopLocationLoop();
    _stopOfferTimer();
    _acceptTimeoutTimer?.cancel();
    activeOffer.value = null;
    offerActionLoading.value = false;
    offerSecondsRemaining.value = 0;
    _disconnectSocket();
    isOnline.value = false;
    socketConnected.value = false;
    isReconnecting.value = false;
  }

  bool _looksAcceptedStatus(Map<String, dynamic> data) {
    final status =
        (_readString(data['status']) ?? _readString(data['result']) ?? '')
            .trim()
            .toLowerCase();
    if (status.isEmpty) return false;
    return status == 'ok' ||
        status == 'accepted' ||
        status == 'success' ||
        status == 'assigned';
  }

  String _resolveSocketUrl() {
    final fromEnv =
        dotenv.env['DRIVER_SOCKET_URL']?.trim() ??
        dotenv.env['SOCKET_URL']?.trim();
    if (fromEnv != null && fromEnv.isNotEmpty) {
      return _normalizeSocketUrl(fromEnv);
    }

    final apiBase = dotenv.env['API_BASE_URL']?.trim();
    if (apiBase != null && apiBase.isNotEmpty) {
      return _normalizeSocketUrl(apiBase);
    }

    throw Exception(
      'Missing DRIVER_SOCKET_URL (or SOCKET_URL / API_BASE_URL) in .env',
    );
  }

  String _normalizeSocketUrl(String rawUrl) {
    final input = rawUrl.trim();
    if (input.isEmpty) return input;

    final withScheme = input.contains('://') ? input : 'http://$input';
    final uri = Uri.tryParse(withScheme);
    if (uri == null || uri.host.isEmpty) return withScheme;

    final isLocalHost = uri.host == 'localhost' || uri.host == '127.0.0.1';
    if (Platform.isAndroid && isLocalHost) {
      // Android emulator reaches host machine via 10.0.2.2.
      return uri.replace(host: '10.0.2.2').toString();
    }

    return uri.toString();
  }

  void _traceRealtime(String message) {
    debugPrint('[DriverRealtime] $message');
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return const <String, dynamic>{};
}

String? _readString(dynamic value) {
  final parsed = value?.toString().trim();
  if (parsed == null || parsed.isEmpty) return null;
  return parsed;
}

bool _readBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final parsed = value?.toString().trim().toLowerCase() ?? '';
  return parsed == 'true' || parsed == '1' || parsed == 'yes';
}

Map<String, dynamic> _firstNonEmptyMap(Iterable<Map<String, dynamic>> maps) {
  for (final map in maps) {
    if (map.isNotEmpty) return map;
  }
  return const <String, dynamic>{};
}

String? _readFirstString({
  required List<Map<String, dynamic>> maps,
  required List<String> keys,
}) {
  for (final map in maps) {
    for (final key in keys) {
      final value = _readString(map[key]);
      if (value != null) return value;
    }
  }
  return null;
}

String? _readFirstAddress({
  required List<Map<String, dynamic>> maps,
  required List<String> keys,
}) {
  for (final map in maps) {
    for (final key in keys) {
      final value = _readAddressValue(map[key]);
      if (value != null) return value;
    }
  }
  return null;
}

double? _readFirstDouble({
  required List<Map<String, dynamic>> maps,
  required bool isLatitude,
  required List<String> keys,
}) {
  for (final map in maps) {
    for (final key in keys) {
      final value = _readCoordinateValue(map[key], isLatitude: isLatitude);
      if (value != null) return value;
    }
  }
  return null;
}

String? _readAddressValue(dynamic value) {
  final map = _asMap(value);
  if (map.isNotEmpty) {
    return _readString(map['address']) ??
        _readString(map['formattedAddress']) ??
        _readString(map['formatted_address']) ??
        _readString(map['fullAddress']) ??
        _readString(map['full_address']) ??
        _readString(map['name']) ??
        _readString(map['label']) ??
        _readString(map['title']) ??
        _readString(map['city']) ??
        _readString(map['city_name']);
  }

  final direct = _readString(value);
  if (direct == null) return null;

  // Some payloads send coordinate objects in pickup/dropoff fields.
  // Don't render raw "{lat: ..., lng: ...}" as the address line.
  final normalized = direct.toLowerCase();
  final looksLikeCoordinateObject =
      normalized.startsWith('{') &&
      normalized.contains('lat') &&
      (normalized.contains('lng') || normalized.contains('lon'));
  if (looksLikeCoordinateObject) return null;
  return direct;
}

double? _readCoordinateValue(dynamic value, {required bool isLatitude}) {
  if (value == null) return null;
  if (value is num) return value.toDouble();

  final direct = double.tryParse(value.toString().trim());
  if (direct != null) return direct;

  final map = _asMap(value);
  if (map.isEmpty) return null;
  if (isLatitude) {
    return _readCoordinateValue(map['lat'], isLatitude: true) ??
        _readCoordinateValue(map['latitude'], isLatitude: true);
  }
  return _readCoordinateValue(map['lng'], isLatitude: false) ??
      _readCoordinateValue(map['lon'], isLatitude: false) ??
      _readCoordinateValue(map['longitude'], isLatitude: false);
}
