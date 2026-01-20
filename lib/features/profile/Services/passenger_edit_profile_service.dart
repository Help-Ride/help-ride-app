

import '../../../shared/services/api_client.dart';
import '../Models/passenger_edit_profile_model.dart';
import '../Models/passenger_edit_profile_request.dart';


class PassengerProfileApi {
  final ApiClient _client;

  PassengerProfileApi(this._client);

  /// Update user profile
  Future<PassengerEditProfile> updateProfile({
    required String userId,
    required PassengerEditProfileRequest request,
  }) async {
    final res = await _client.put(
      '/users/$userId',
      data: request.toJson(),
    );

    print('Update profile response: ${res.data}');

    return PassengerEditProfile.fromJson(res.data);
  }

}
