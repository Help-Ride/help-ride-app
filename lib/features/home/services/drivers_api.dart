import '../../../shared/services/api_client.dart';

class DriversApi {
  DriversApi(this._client);
  final ApiClient _client;

  Future<void> createDriverProfile({
    String? carMake,
    String? carModel,
    String? carYear,
    String? carColor,
    String? plateNumber,
    String? licenseNumber,
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
}
