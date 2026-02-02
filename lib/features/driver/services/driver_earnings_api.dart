import '../../../shared/services/api_client.dart';

class DriverEarningsBucket {
  const DriverEarningsBucket({
    required this.paymentsCount,
    required this.amountCents,
  });

  final int paymentsCount;
  final int amountCents;
}

class DriverSummary {
  const DriverSummary({
    required this.ridesTotal,
    required this.ridesCompleted,
    required this.pending,
    required this.paid,
    required this.refunded,
    required this.failed,
    required this.netCollectedCents,
  });

  const DriverSummary.empty()
    : ridesTotal = 0,
      ridesCompleted = 0,
      pending = const DriverEarningsBucket(paymentsCount: 0, amountCents: 0),
      paid = const DriverEarningsBucket(paymentsCount: 0, amountCents: 0),
      refunded = const DriverEarningsBucket(paymentsCount: 0, amountCents: 0),
      failed = const DriverEarningsBucket(paymentsCount: 0, amountCents: 0),
      netCollectedCents = 0;

  final int ridesTotal;
  final int ridesCompleted;
  final DriverEarningsBucket pending;
  final DriverEarningsBucket paid;
  final DriverEarningsBucket refunded;
  final DriverEarningsBucket failed;
  final int netCollectedCents;
}

class DriverEarningPassenger {
  const DriverEarningPassenger({
    required this.id,
    required this.name,
    required this.email,
  });

  final String id;
  final String name;
  final String email;

  factory DriverEarningPassenger.fromJson(Map<String, dynamic> json) {
    return DriverEarningPassenger(
      id: _readString(json['id']),
      name: _readString(json['name']),
      email: _readString(json['email']),
    );
  }
}

class DriverEarningRide {
  const DriverEarningRide({
    required this.id,
    required this.fromCity,
    required this.toCity,
    this.startTime,
    required this.status,
  });

  final String id;
  final String fromCity;
  final String toCity;
  final DateTime? startTime;
  final String status;

  factory DriverEarningRide.fromJson(Map<String, dynamic> json) {
    return DriverEarningRide(
      id: _readString(json['id']),
      fromCity: _readString(json['fromCity'] ?? json['from_city']),
      toCity: _readString(json['toCity'] ?? json['to_city']),
      startTime: _readDateTime(json['startTime'] ?? json['start_time']),
      status: _readString(json['status']),
    );
  }
}

class DriverEarningBooking {
  const DriverEarningBooking({
    required this.id,
    required this.status,
    required this.paymentStatus,
    required this.seatsBooked,
    this.passenger,
    this.ride,
  });

  final String id;
  final String status;
  final String paymentStatus;
  final int seatsBooked;
  final DriverEarningPassenger? passenger;
  final DriverEarningRide? ride;

  factory DriverEarningBooking.fromJson(Map<String, dynamic> json) {
    final passengerMap = _asMap(json['passenger']);
    final rideMap = _asMap(json['ride']);

    return DriverEarningBooking(
      id: _readString(json['id']),
      status: _readString(json['status']),
      paymentStatus: _readString(
        json['paymentStatus'] ?? json['payment_status'],
      ),
      seatsBooked: _readInt(json['seatsBooked'] ?? json['seats_booked']),
      passenger: passengerMap.isEmpty
          ? null
          : DriverEarningPassenger.fromJson(passengerMap),
      ride: rideMap.isEmpty ? null : DriverEarningRide.fromJson(rideMap),
    );
  }
}

class DriverEarningPayment {
  const DriverEarningPayment({
    required this.id,
    required this.paymentIntentId,
    required this.amountCents,
    required this.platformFeeCents,
    required this.driverEarningsCents,
    required this.currency,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.booking,
  });

  final String id;
  final String paymentIntentId;
  final int amountCents;
  final int platformFeeCents;
  final int driverEarningsCents;
  final String currency;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DriverEarningBooking? booking;

  factory DriverEarningPayment.fromJson(Map<String, dynamic> json) {
    final bookingMap = _asMap(json['booking']);
    return DriverEarningPayment(
      id: _readString(json['id']),
      paymentIntentId: _readString(
        json['paymentIntentId'] ?? json['payment_intent_id'],
      ),
      amountCents: _readInt(json['amountCents'] ?? json['amount_cents']),
      platformFeeCents: _readInt(
        json['platformFeeCents'] ?? json['platform_fee_cents'],
      ),
      driverEarningsCents: _readInt(
        json['driverEarningsCents'] ?? json['driver_earnings_cents'],
      ),
      currency: _readString(json['currency']).toUpperCase(),
      status: _readString(json['status']),
      createdAt: _readDateTime(json['createdAt'] ?? json['created_at']),
      updatedAt: _readDateTime(json['updatedAt'] ?? json['updated_at']),
      booking: bookingMap.isEmpty
          ? null
          : DriverEarningBooking.fromJson(bookingMap),
    );
  }
}

class DriverEarningsPage {
  const DriverEarningsPage({required this.payments, required this.nextCursor});

  final List<DriverEarningPayment> payments;
  final String? nextCursor;
}

class DriverEarningsApi {
  DriverEarningsApi(this._client);
  final ApiClient _client;

  Future<DriverSummary> fetchDriverSummary() async {
    final res = await _client.get<dynamic>('/drivers/me/summary');
    final body = _extractDataBody(res.data);

    final ridesMap = _asMap(body['rides']);
    final earningsMap = _asMap(body['earnings']);

    return DriverSummary(
      ridesTotal: _readInt(ridesMap['total']),
      ridesCompleted: _readInt(ridesMap['completed']),
      pending: _readBucket(_asMap(earningsMap['pending'])),
      paid: _readBucket(_asMap(earningsMap['paid'])),
      refunded: _readBucket(_asMap(earningsMap['refunded'])),
      failed: _readBucket(_asMap(earningsMap['failed'])),
      netCollectedCents: _readInt(
        earningsMap['netCollectedCents'] ?? earningsMap['net_collected_cents'],
      ),
    );
  }

  Future<DriverEarningsPage> fetchDriverEarnings({
    String status = 'succeeded',
    int limit = 20,
    String? cursor,
  }) async {
    final response = await _client.get<dynamic>(
      '/drivers/me/earnings',
      query: {
        'status': status,
        'limit': limit,
        if (cursor != null && cursor.trim().isNotEmpty) 'cursor': cursor.trim(),
      },
    );

    final body = _extractDataBody(response.data);
    final paymentsRaw = body['payments'];

    final payments = paymentsRaw is List
        ? paymentsRaw
              .whereType<Map>()
              .map(
                (item) =>
                    DriverEarningPayment.fromJson(item.cast<String, dynamic>()),
              )
              .toList()
        : <DriverEarningPayment>[];

    final nextCursor =
        _readOptionalString(body['nextCursor']) ??
        _readOptionalString(body['next_cursor']);

    return DriverEarningsPage(payments: payments, nextCursor: nextCursor);
  }

  DriverEarningsBucket _readBucket(Map<String, dynamic> bucket) {
    return DriverEarningsBucket(
      paymentsCount: _readInt(
        bucket['paymentsCount'] ?? bucket['payments_count'],
      ),
      amountCents: _readInt(bucket['amountCents'] ?? bucket['amount_cents']),
    );
  }

  Map<String, dynamic> _extractDataBody(dynamic raw) {
    final root = _asMap(raw);
    final data = _asMap(root['data']);
    return data.isNotEmpty ? data : root;
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) {
    return value.cast<String, dynamic>();
  }
  return const <String, dynamic>{};
}

String _readString(dynamic value) {
  return value?.toString().trim() ?? '';
}

String? _readOptionalString(dynamic value) {
  final parsed = _readString(value);
  return parsed.isEmpty ? null : parsed;
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _readDateTime(dynamic value) {
  final raw = _readOptionalString(value);
  if (raw == null) return null;
  final parsed = DateTime.tryParse(raw);
  return parsed?.toLocal();
}
