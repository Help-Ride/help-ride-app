import 'package:help_ride/shared/services/api_client.dart';

class PaymentIntentSession {
  const PaymentIntentSession({
    required this.clientSecret,
    this.paymentIntentId,
    this.amount,
    this.currency,
  });

  final String clientSecret;
  final String? paymentIntentId;
  final int? amount;
  final String? currency;
}

class PaymentIntentStatus {
  const PaymentIntentStatus({
    required this.paymentIntentId,
    required this.intentStatus,
    this.bookingPaymentStatus,
    this.amount,
    this.currency,
  });

  final String paymentIntentId;
  final String intentStatus;
  final String? bookingPaymentStatus;
  final int? amount;
  final String? currency;
}

class PaymentsApi {
  PaymentsApi(this._client);

  final ApiClient _client;
  String get _intentPath {
    final base = _client.dio.options.baseUrl.trim().toLowerCase();
    if (base.endsWith('/api')) return '/payments/intent';
    return 'payments/intent';
  }

  Future<PaymentIntentSession> createPaymentIntent({
    required String bookingId,
  }) async {
    final id = bookingId.trim();
    if (id.isEmpty) throw Exception('Missing bookingId');

    final res = await _client.post<dynamic>(
      _intentPath,
      data: {'bookingId': id},
    );

    final root = _toMap(res.data);
    final nested = _toMap(root['data']);

    final rawStringSecret = res.data is String ? (res.data as String) : null;
    final secret =
        _readClientSecret(root) ?? _readClientSecret(nested) ?? rawStringSecret;
    final paymentIntentId =
        _readPaymentIntentId(root) ?? _readPaymentIntentId(nested);
    final amount = _readAmount(root) ?? _readAmount(nested);
    final currency = _readCurrency(root) ?? _readCurrency(nested);

    if (secret == null || secret.trim().isEmpty) {
      throw Exception('Missing payment intent client secret.');
    }

    final cleanedSecret = secret.trim();
    final cleanedIntentId = (paymentIntentId ?? '').trim();

    return PaymentIntentSession(
      clientSecret: cleanedSecret,
      paymentIntentId: cleanedIntentId.isEmpty
          ? _intentIdFromClientSecret(cleanedSecret)
          : cleanedIntentId,
      amount: amount,
      currency: currency,
    );
  }

  Future<PaymentIntentStatus> getPaymentIntentStatus({
    required String paymentIntentId,
  }) async {
    final id = paymentIntentId.trim();
    if (id.isEmpty) throw Exception('Missing paymentIntentId');

    final res = await _client.get<dynamic>('$_intentPath/$id');
    final root = _toMap(res.data);
    final nested = _toMap(root['data']);

    final resolvedId =
        (_readPaymentIntentId(root) ?? _readPaymentIntentId(nested) ?? id)
            .trim();
    final intentStatus =
        (_readIntentStatus(root) ?? _readIntentStatus(nested) ?? 'pending')
            .trim()
            .toLowerCase();
    final bookingPaymentStatus =
        (_readBookingPaymentStatus(root) ?? _readBookingPaymentStatus(nested))
            ?.trim()
            .toLowerCase();
    final amount = _readAmount(root) ?? _readAmount(nested);
    final currency = _readCurrency(root) ?? _readCurrency(nested);

    return PaymentIntentStatus(
      paymentIntentId: resolvedId.isEmpty ? id : resolvedId,
      intentStatus: intentStatus,
      bookingPaymentStatus: bookingPaymentStatus,
      amount: amount,
      currency: currency,
    );
  }

  String? _readClientSecret(Map<String, dynamic> data) {
    final raw =
        data['clientSecret'] ??
        data['client_secret'] ??
        data['paymentIntentClientSecret'] ??
        data['payment_intent_client_secret'] ??
        (_toMap(data['paymentIntent'])['client_secret']) ??
        (_toMap(data['payment_intent'])['client_secret']);
    final value = raw?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  String? _readPaymentIntentId(Map<String, dynamic> data) {
    final raw =
        data['paymentIntentId'] ??
        data['payment_intent_id'] ??
        (_toMap(data['paymentIntent'])['id']) ??
        (_toMap(data['payment_intent'])['id']) ??
        data['id'];
    if (raw is Map) {
      return _normalizePaymentIntentId(raw['id']);
    }
    return _normalizePaymentIntentId(raw);
  }

  String? _intentIdFromClientSecret(String clientSecret) {
    final marker = '_secret_';
    final idx = clientSecret.indexOf(marker);
    if (idx <= 0) return null;
    return clientSecret.substring(0, idx);
  }

  String? _normalizePaymentIntentId(dynamic raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) return null;
    if (!value.startsWith('pi_')) return null;
    return value;
  }

  int? _readAmount(Map<String, dynamic> data) {
    final raw =
        data['amount'] ??
        data['amount_cents'] ??
        data['amountCents'] ??
        (_toMap(data['paymentIntent'])['amount']) ??
        (_toMap(data['payment_intent'])['amount']);
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    return int.tryParse(raw?.toString() ?? '');
  }

  String? _readCurrency(Map<String, dynamic> data) {
    final raw =
        data['currency'] ??
        (_toMap(data['paymentIntent'])['currency']) ??
        (_toMap(data['payment_intent'])['currency']);
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) return null;
    return value.toUpperCase();
  }

  String? _readIntentStatus(Map<String, dynamic> data) {
    final raw =
        data['status'] ??
        data['paymentIntentStatus'] ??
        data['payment_intent_status'] ??
        (_toMap(data['paymentIntent'])['status']) ??
        (_toMap(data['payment_intent'])['status']);
    final value = raw?.toString();
    return value == null || value.trim().isEmpty ? null : value;
  }

  String? _readBookingPaymentStatus(Map<String, dynamic> data) {
    final raw =
        data['bookingPaymentStatus'] ??
        data['booking_payment_status'] ??
        data['paymentStatus'] ??
        data['payment_status'] ??
        (_toMap(data['booking'])['paymentStatus']) ??
        (_toMap(data['booking'])['bookingPaymentStatus']);
    final value = raw?.toString();
    return value == null || value.trim().isEmpty ? null : value;
  }

  Map<String, dynamic> _toMap(dynamic value) {
    if (value is Map) {
      return value.cast<String, dynamic>();
    }
    return const <String, dynamic>{};
  }
}
