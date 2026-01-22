import '../../../shared/services/api_client.dart';
import '../Models/passenger_ride_request_model.dart';

class RideRequestService {
  final ApiClient _apiClient;

  RideRequestService(this._apiClient);

  Future<PassengerRideRequestModel> createRideRequest({
    required PassengerRideRequestModel request,
  }) async {
    final response = await _apiClient.post(
      '/ride-requests',
      data: request.toJson(),
    );
    print('Ride Request API Response--- ${response.data}');

    return PassengerRideRequestModel.fromJson(response.data);
  }
}
