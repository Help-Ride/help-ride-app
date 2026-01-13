import '../../../shared/services/api_client.dart';

class DriversApi {
  DriversApi(this._client);
  final ApiClient _client;

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
}
