import '../../../shared/services/api_client.dart';
import '../Models/passenger_search_ride_model.dart';

class PassengerRidesApi {
  PassengerRidesApi(this._client);

  final ApiClient _client;

  /// GET /rides?fromCity=Waterloo&toCity=Toronto&seats=1
  Future<List<PassengerSearchRidesModel>> searchRides({
    required String fromCity,
    required String toCity,
    required int seats,
  }) async {
    final res = await _client.get<List<dynamic>>(
      '/rides',
      query: {
        'fromCity': fromCity,
        'toCity': toCity,
        'seats': seats,
      },
    );
    print("🔹 API Response (raw): ${res.data}");

    final data = res.data ?? [];

    return data
        .map(
          (e) => PassengerSearchRidesModel.fromJson(
        e as Map<String, dynamic>,
      ),
    )
        .toList();


  }
}
