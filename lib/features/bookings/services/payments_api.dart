import 'package:help_ride/shared/services/api_client.dart';

class PaymentIntentSession {
  const PaymentIntentSession({
    required this.clientSecret,
    this.paymentIntentId,
    this.amount,
    this.currency,
    this.customerId,
    this.customerEphemeralKeySecret,
  });

  final String clientSecret;
  final String? paymentIntentId;
  final int? amount;
  final String? currency;
  final String? customerId;
  final String? customerEphemeralKeySecret;
}

class CustomerSheetSession {
  const CustomerSheetSession({
    required this.setupIntentClientSecret,
    required this.customerId,
    required this.customerEphemeralKeySecret,
  });

  final String setupIntentClientSecret;
  final String customerId;
  final String customerEphemeralKeySecret;
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
  String get _paymentsBasePath {
    final base = _client.dio.options.baseUrl.trim().toLowerCase();
    if (base.endsWith('/api')) return '/payments';
    return 'payments';
  }

  String get _intentPath => '$_paymentsBasePath/intent';

  String get _setupIntentPath => '$_paymentsBasePath/setup-intent';

  Future<PaymentIntentSession> createPaymentIntent({
    required String bookingId,
    required bool savePaymentMethod,
  }) async {
    final id = bookingId.trim();
    if (id.isEmpty) throw Exception('Missing bookingId');

    final res = await _client.post<dynamic>(
      _intentPath,
      data: {'bookingId': id, 'savePaymentMethod': savePaymentMethod},
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
    final customerId = _readCustomerId(root) ?? _readCustomerId(nested);
    final customerEphemeralKeySecret =
        _readCustomerEphemeralKeySecret(root) ??
        _readCustomerEphemeralKeySecret(nested);

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
      customerId: customerId,
      customerEphemeralKeySecret: customerEphemeralKeySecret,
    );
  }

  Future<CustomerSheetSession> createCustomerSheetSession() async {
    final res = await _client.post<dynamic>(
      _setupIntentPath,
      data: const <String, dynamic>{},
    );

    final root = _toMap(res.data);
    final nested = _toMap(root['data']);

    final setupIntentClientSecret =
        _readSetupIntentClientSecret(root) ??
        _readSetupIntentClientSecret(nested);
    final customerId = _readCustomerId(root) ?? _readCustomerId(nested);
    final customerEphemeralKeySecret =
        _readCustomerEphemeralKeySecret(root) ??
        _readCustomerEphemeralKeySecret(nested);

    if (setupIntentClientSecret == null || setupIntentClientSecret.isEmpty) {
      throw Exception('Missing setup intent client secret.');
    }
    if (customerId == null || customerId.isEmpty) {
      throw Exception('Missing Stripe customer ID.');
    }
    if (customerEphemeralKeySecret == null ||
        customerEphemeralKeySecret.isEmpty) {
      throw Exception('Missing Stripe customer ephemeral key.');
    }

    return CustomerSheetSession(
      setupIntentClientSecret: setupIntentClientSecret,
      customerId: customerId,
      customerEphemeralKeySecret: customerEphemeralKeySecret,
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

  String? _readSetupIntentClientSecret(Map<String, dynamic> data) {
    final raw =
        data['setupIntentClientSecret'] ??
        data['setup_intent_client_secret'] ??
        data['clientSecret'] ??
        data['client_secret'] ??
        (_toMap(data['setupIntent'])['client_secret']) ??
        (_toMap(data['setup_intent'])['client_secret']);
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

  String? _readCustomerId(Map<String, dynamic> data) {
    final raw =
        data['customerId'] ??
        data['customer_id'] ??
        (_toMap(data['customer'])['id']);
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  String? _readCustomerEphemeralKeySecret(Map<String, dynamic> data) {
    final raw =
        data['customerEphemeralKeySecret'] ??
        data['customer_ephemeral_key_secret'] ??
        data['ephemeralKeySecret'] ??
        data['ephemeral_key_secret'];
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) return null;
    return value;
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
