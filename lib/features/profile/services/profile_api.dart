import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../shared/services/api_client.dart';
import '../../../shared/models/user.dart';
import '../models/driver_document.dart';

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

  Future<DriverDocumentPresign> getDriverDocumentPresign(
    String userId, {
    required String type,
    required String fileName,
    required String mimeType,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/drivers/$userId/documents/presign',
      data: {'type': type, 'fileName': fileName, 'mimeType': mimeType},
    );

    final payload = _extractMap(res.data);
    final uploadUrl =
        payload['uploadUrl'] ??
        payload['url'] ??
        payload['presignedUrl'] ??
        payload['presignUrl'];
    if (uploadUrl == null || uploadUrl.toString().trim().isEmpty) {
      throw Exception('Could not get upload URL.');
    }

    return DriverDocumentPresign(
      uploadUrl: uploadUrl.toString(),
      documentId: (payload['documentId'] ?? payload['id'])?.toString(),
      key: payload['key']?.toString(),
      publicUrl:
          (payload['publicUrl'] ??
                  payload['fileUrl'] ??
                  payload['assetUrl'] ??
                  payload['cdnUrl'] ??
                  payload['downloadUrl'])
              ?.toString(),
    );
  }

  Future<DriverDocumentPresign> getUserAvatarPresign(
    String userId, {
    required String fileName,
    required String mimeType,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/users/$userId/avatar/presign',
      data: {'fileName': fileName, 'mimeType': mimeType},
    );

    final payload = _extractMap(res.data);
    final uploadUrl =
        payload['uploadUrl'] ??
        payload['url'] ??
        payload['presignedUrl'] ??
        payload['presignUrl'];
    if (uploadUrl == null || uploadUrl.toString().trim().isEmpty) {
      throw Exception('Could not get avatar upload URL.');
    }

    final avatarRaw = payload['avatar'];
    final avatar = avatarRaw is Map
        ? Map<String, dynamic>.from(avatarRaw)
        : const <String, dynamic>{};

    return DriverDocumentPresign(
      uploadUrl: uploadUrl.toString(),
      key: (avatar['s3Key'] ?? payload['s3Key'] ?? payload['key'])?.toString(),
      publicUrl:
          (avatar['url'] ??
                  payload['url'] ??
                  payload['publicUrl'] ??
                  payload['fileUrl'] ??
                  payload['assetUrl'] ??
                  payload['cdnUrl'] ??
                  payload['downloadUrl'])
              ?.toString(),
    );
  }

  Future<void> uploadFileToPresignedUrl({
    required String uploadUrl,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );

    final res = await dio.put<dynamic>(
      uploadUrl,
      data: bytes,
      options: Options(
        headers: {'Content-Type': mimeType},
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ),
    );

    if (res.statusCode == null ||
        res.statusCode! < 200 ||
        res.statusCode! >= 300) {
      throw Exception('Document upload failed.');
    }
  }

  Future<List<DriverDocument>> getDriverDocuments(String userId) async {
    final res = await _client.get<dynamic>('/drivers/$userId/documents');
    final raw = _extractList(res.data);
    return raw
        .whereType<Map>()
        .map((m) => DriverDocument.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Map<String, dynamic> _extractMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      if (raw['data'] is Map<String, dynamic>) {
        return raw['data'] as Map<String, dynamic>;
      }
      return raw;
    }
    if (raw is Map && raw['data'] is Map) {
      return Map<String, dynamic>.from(raw['data'] as Map);
    }
    throw Exception('Unexpected API response format.');
  }

  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is List) return data;
      final documents = raw['documents'];
      if (documents is List) return documents;
    }
    if (raw is Map) {
      final data = raw['data'];
      if (data is List) return data;
      final documents = raw['documents'];
      if (documents is List) return documents;
    }
    return const [];
  }
}
