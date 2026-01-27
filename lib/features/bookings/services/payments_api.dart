import 'package:help_ride/shared/services/api_client.dart';

class PaymentsApi {
  PaymentsApi(this._client);

  final ApiClient _client;

  Future<String> createPaymentIntent({required String bookingId}) async {
    final id = bookingId.trim();
    if (id.isEmpty) throw Exception('Missing bookingId');

    final res = await _client.post<dynamic>(
      '/payments/intent',
      data: {'bookingId': id},
    );

    final data = res.data;
    String? secret;

    if (data is Map) {
      secret = _readClientSecret(data.cast<String, dynamic>());
      final nested = data['data'];
      if ((secret == null || secret.isEmpty) && nested is Map) {
        secret = _readClientSecret(nested.cast<String, dynamic>());
      }
    } else if (data is String) {
      secret = data;
    }

    if (secret == null || secret.trim().isEmpty) {
      throw Exception('Missing payment intent client secret.');
    }

    return secret.trim();
  }

  String? _readClientSecret(Map<String, dynamic> data) {
    final raw = data['clientSecret'] ??
        data['client_secret'] ??
        data['paymentIntentClientSecret'] ??
        data['payment_intent_client_secret'];
    return raw?.toString();
  }
}
