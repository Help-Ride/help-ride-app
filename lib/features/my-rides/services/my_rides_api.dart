import 'package:get/get.dart';
import '../../../shared/services/api_client.dart';
import '../models/passenger_my_ride_list.dart';

class MyRidesApi {
  MyRidesApi(this._client);

  final ApiClient _client;


  Future<List<PassengerMyRideList>> getMyRides() async {
    final response = await _client.get('/bookings/me/list');

    print('RESPONSE: ${response.data}');
    print('Status code: ${response.statusCode}');

    if (response.statusCode == 200 && response.data != null) {
      final List<dynamic> list = response.data;

      return list
          .map((e) => PassengerMyRideList.fromJson(e))
          .toList();
    } else {
      throw Exception('Failed to load my rides');
    }
  }


  // Future<List<PassengerMyRideList>> getMyRides() async {
  //   final response = await _client.get('/bookings/me/list');
  //
  //   print('RESPONSE: ${response.data}');
  //   print('Status code: ${response.statusCode}');
  //
  //   if (response.statusCode == 200 && response.data != null) {
  //
  //     // 👉 Parse the "data" field
  //     final List<dynamic> list = response.data['data'];
  //
  //     return list
  //         .map((e) => PassengerMyRideList.fromJson(e))
  //         .toList();
  //   } else {
  //     throw Exception('Failed to load my rides');
  //   }
  // }


}
