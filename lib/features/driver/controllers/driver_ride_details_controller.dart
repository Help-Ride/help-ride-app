import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:help_ride/features/bookings/models/booking.dart';
import 'package:help_ride/features/bookings/services/bookings_api.dart';
import 'package:help_ride/features/driver/services/driver_rides_api.dart';
import 'package:help_ride/features/rides/models/ride.dart';
import 'package:help_ride/features/rides/services/rides_api.dart';
import 'package:help_ride/shared/services/api_exception.dart';
import 'package:help_ride/shared/services/api_client.dart';

enum DriverRideRequestsTab { all, newRequests, offered }

class DriverRideDetailsController extends GetxController {
  final loading = false.obs;
  final error = RxnString();
  final ride = Rxn<Ride>();

  final requestsLoading = false.obs;
  final requestsError = RxnString();
  final requests = <Booking>[].obs;
  final requestsTab = DriverRideRequestsTab.all.obs;
  final actionIds = <String>{}.obs;
  final rideActionLoading = false.obs;
  final rideActionError = RxnString();
  final unpaidBlockingBookingIds = <String>[].obs;

  late final RidesApi _ridesApi;
  late final DriverRidesApi _driverRidesApi;
  late final BookingsApi _bookingsApi;

  String get rideId => Get.parameters['id'] ?? '';

  @override
  Future<void> onInit() async {
    super.onInit();
    final client = await ApiClient.create();
    _ridesApi = RidesApi(client);
    _driverRidesApi = DriverRidesApi(client);
    _bookingsApi = BookingsApi(client);

    if (rideId.trim().isEmpty) {
      error.value = 'Missing ride id.';
      return;
    }

    await fetch();
    await fetchRequests();
  }

  Future<void> fetch() async {
    loading.value = true;
    error.value = null;
    try {
      ride.value = await _ridesApi.getRideById(rideId);
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  void setRequestsTab(DriverRideRequestsTab t) => requestsTab.value = t;

  bool isActing(String id) => actionIds.contains(id);

  bool get canStartRide {
    final status = ride.value?.status.toLowerCase() ?? '';
    return status.contains('open') || status.contains('scheduled');
  }

  bool get canCompleteRide {
    final status = ride.value?.status.toLowerCase() ?? '';
    return status.contains('ongoing') || status.contains('in_progress');
  }

  bool _isNew(Booking b) {
    final s = b.status.toLowerCase();
    return s.contains('pending') ||
        s.contains('new') ||
        s.contains('requested') ||
        s.contains('request');
  }

  bool _isOffered(Booking b) {
    final s = b.status.toLowerCase();
    return s.contains('confirm') ||
        s.contains('accepted') ||
        s.contains('offer');
  }

  List<Booking> get filteredRequests {
    if (requestsTab.value == DriverRideRequestsTab.all) return requests;
    if (requestsTab.value == DriverRideRequestsTab.newRequests) {
      return requests.where(_isNew).toList();
    }
    return requests.where(_isOffered).toList();
  }

  int get newCount => requests.where(_isNew).length;
  int get offeredCount => requests.where(_isOffered).length;

  Future<void> fetchRequests() async {
    requestsLoading.value = true;
    requestsError.value = null;
    try {
      final list = await _bookingsApi.bookingsForRide(rideId);
      list.sort((a, b) => _bookingSortTime(b).compareTo(_bookingSortTime(a)));
      requests.assignAll(list);
    } catch (e) {
      requestsError.value = e.toString();
    } finally {
      requestsLoading.value = false;
    }
  }

  DateTime _bookingSortTime(Booking b) => b.updatedAt ?? b.createdAt;

  Booking _withStatus(Booking b, String status) {
    return Booking(
      id: b.id,
      rideId: b.rideId,
      rideRequestId: b.rideRequestId,
      passengerId: b.passengerId,
      seatsBooked: b.seatsBooked,
      status: status,
      paymentStatus: b.paymentStatus,
      paymentIntentId: b.paymentIntentId,
      createdAt: b.createdAt,
      updatedAt: DateTime.now(),
      ride: b.ride,
      passenger: b.passenger,
      note: b.note,
    );
  }

  void _updateStatus(String bookingId, String status) {
    final idx = requests.indexWhere((b) => b.id == bookingId);
    if (idx == -1) return;
    requests[idx] = _withStatus(requests[idx], status);
  }

  Future<void> confirmBooking(String bookingId) async {
    if (isActing(bookingId)) return;
    actionIds.add(bookingId);
    actionIds.refresh();
    try {
      await _bookingsApi.confirmBooking(bookingId);
      _updateStatus(bookingId, 'confirmed');
      Get.snackbar('Offer sent', 'Booking confirmed.');
    } catch (e) {
      Get.snackbar('Failed', e.toString());
    } finally {
      actionIds.remove(bookingId);
      actionIds.refresh();
    }
  }

  Future<void> rejectBooking(String bookingId) async {
    if (isActing(bookingId)) return;
    actionIds.add(bookingId);
    actionIds.refresh();
    try {
      await _bookingsApi.rejectBooking(bookingId);
      _updateStatus(bookingId, 'rejected');
      Get.snackbar('Declined', 'Booking rejected.');
    } catch (e) {
      Get.snackbar('Failed', e.toString());
    } finally {
      actionIds.remove(bookingId);
      actionIds.refresh();
    }
  }

  Future<void> startRide() async {
    await _runRideLifecycleAction(
      action: () => _driverRidesApi.startRide(rideId),
      successTitle: 'Ride started',
      successMessage: 'Ride is now in progress.',
    );
  }

  Future<void> completeRide() async {
    await _runRideLifecycleAction(
      action: () => _driverRidesApi.completeRide(rideId),
      successTitle: 'Ride completed',
      successMessage: 'Ride marked as completed.',
    );
  }

  Future<void> _runRideLifecycleAction({
    required Future<Map<String, dynamic>> Function() action,
    required String successTitle,
    required String successMessage,
  }) async {
    if (rideActionLoading.value) return;
    if (rideId.trim().isEmpty) return;

    rideActionLoading.value = true;
    rideActionError.value = null;
    unpaidBlockingBookingIds.clear();

    try {
      await action();
      await fetch();
      await fetchRequests();
      Get.snackbar(successTitle, successMessage);
    } catch (e) {
      final block = _extractPaymentBlock(e);
      if (block != null) {
        rideActionError.value = block.message;
        unpaidBlockingBookingIds.assignAll(block.unpaidBookingIds);
        final suffix = block.unpaidBookingIds.isEmpty
            ? ''
            : ' (${block.unpaidBookingIds.join(', ')})';
        Get.snackbar('Action blocked', '${block.message}$suffix');
      } else {
        rideActionError.value = 'Could not update ride status.';
        Get.snackbar('Failed', e.toString());
      }
    } finally {
      rideActionLoading.value = false;
    }
  }

  _PaymentBlockInfo? _extractPaymentBlock(Object error) {
    ApiException? apiError;
    if (error is ApiException) {
      apiError = error;
    } else if (error is DioException && error.error is ApiException) {
      apiError = error.error as ApiException;
    }
    if (apiError == null) return null;

    final details = apiError.details;
    if (details is! Map) return null;
    final map = details.cast<String, dynamic>();

    final ids = _extractUnpaidBookingIds(map);
    if (ids.isEmpty) return null;

    final message = (map['message'] ?? map['error'] ?? apiError.message)
        .toString();
    return _PaymentBlockInfo(message: message, unpaidBookingIds: ids);
  }

  List<String> _extractUnpaidBookingIds(Map<String, dynamic> map) {
    final direct = _toStringList(map['unpaidBookingIds']);
    if (direct.isNotEmpty) return direct;

    final snakeCase = _toStringList(map['unpaid_booking_ids']);
    if (snakeCase.isNotEmpty) return snakeCase;

    final data = map['data'];
    if (data is Map) {
      return _extractUnpaidBookingIds(data.cast<String, dynamic>());
    }
    return const [];
  }

  List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }
}

class _PaymentBlockInfo {
  const _PaymentBlockInfo({
    required this.message,
    required this.unpaidBookingIds,
  });

  final String message;
  final List<String> unpaidBookingIds;
}
