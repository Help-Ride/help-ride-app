import '../../../shared/services/api_client.dart';
import '../../../shared/models/user.dart';

class ProfileApi {
  ProfileApi(this._client);
  final ApiClient _client;

  Future<DriverProfile?> getDriverProfile(String userId) async {
    final res = await _client.get('/drivers/$userId');
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return DriverProfile.fromJson(data);
    }
    if (data is Map && data['data'] is Map<String, dynamic>) {
      return DriverProfile.fromJson(data['data']);
    }
    return null;
  }

  Future<void> createDriverProfile({
    required String carMake,
    required String carModel,
    String? carYear,
    String? carColor,
    required String plateNumber,
    required String licenseNumber,
    String? insuranceInfo,
  }) async {
    await _client.post<Map<String, dynamic>>(
      '/drivers',
      data: {
        'carMake': carMake,
        'carModel': carModel,
        'carYear': carYear,
        'carColor': carColor,
        'plateNumber': plateNumber,
        'licenseNumber': licenseNumber,
        'insuranceInfo': insuranceInfo,
      },
    );
  }

  Future<void> updateDriverProfile(
    String userId, {
    String? carMake,
    String? carModel,
    String? carYear,
    String? carColor,
    String? plateNumber,
    String? licenseNumber,
    String? insuranceInfo,
  }) async {
    await _client.put<Map<String, dynamic>>(
      '/drivers/$userId',
      data: {
        if (carMake != null) 'carMake': carMake,
        if (carModel != null) 'carModel': carModel,
        if (carYear != null) 'carYear': carYear,
        if (carColor != null) 'carColor': carColor,
        if (plateNumber != null) 'plateNumber': plateNumber,
        if (licenseNumber != null) 'licenseNumber': licenseNumber,
        if (insuranceInfo != null) 'insuranceInfo': insuranceInfo,
      },
    );
  }

  Future<void> updateUserProfile(
    String userId, {
    String? name,
    String? phone,
    String? providerAvatarUrl,
  }) async {
    await _client.put<Map<String, dynamic>>(
      '/users/$userId',
      data: {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (providerAvatarUrl != null) 'providerAvatarUrl': providerAvatarUrl,
      },
    );
  }

  Future<String> createStripeOnboarding() async {
    final res = await _client.post<dynamic>('/stripe/connect/onboard');
    final data = res.data;
    String? url;

    if (data is Map) {
      url = _readOnboardingUrl(data.cast<String, dynamic>());
      final nested = data['data'];
      if ((url == null || url.isEmpty) && nested is Map) {
        url = _readOnboardingUrl(nested.cast<String, dynamic>());
      }
    } else if (data is String) {
      url = data;
    }

    if (url == null || url.trim().isEmpty) {
      throw Exception('Missing Stripe onboarding URL.');
    }

    return url.trim();
  }

  String? _readOnboardingUrl(Map<String, dynamic> data) {
    final raw = data['url'] ??
        data['onboardingUrl'] ??
        data['onboarding_url'] ??
        data['link'];
    return raw?.toString();
  }
}
