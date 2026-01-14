import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart' hide Response;

import 'package:help_ride/shared/controllers/session_controller.dart';
import 'token_storage.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient._(this._dio);
  final Dio _dio;

  Dio get dio => _dio;

  static const _skipAuthLogoutKey = 'skipAuthLogout';

  static Future<ApiClient> create() async {
    final baseUrl = dotenv.env['API_BASE_URL'];
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('Missing API_BASE_URL in .env');
    }

    final tokenStorage = TokenStorage();

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
        // keep default validateStatus (throws on non-2xx)
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (e, handler) async {
          final status = e.response?.statusCode;

          // ✅ Optional logging (don’t spam in release)
          if (kDebugMode) {
            debugPrint(
              'API Error: $status ${e.requestOptions.method} ${e.requestOptions.path}\n'
              'Data: ${e.response?.data}',
            );
          }

          // ✅ Only auto-logout on 401 when it's NOT an auth call
          final skipLogout = e.requestOptions.extra[_skipAuthLogoutKey] == true;
          if (status == 401 && !skipLogout) {
            await tokenStorage.clear();
            if (Get.isRegistered<SessionController>()) {
              await Get.find<SessionController>().logout();
            }
            Get.offAllNamed('/login');
          }

          // ✅ Convert to a clean exception the UI can show
          final apiEx = _toApiException(e);
          return handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              response: e.response,
              type: e.type,
              error: apiEx,
            ),
          );
        },
      ),
    );

    return ApiClient._(dio);
  }

  // --- Public methods ---

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    bool skipAuthLogout = false,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: query,
      options: Options(extra: {_skipAuthLogoutKey: skipAuthLogout}),
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    bool skipAuthLogout = false,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      options: Options(extra: {_skipAuthLogoutKey: skipAuthLogout}),
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    bool skipAuthLogout = false,
  }) {
    return _dio.patch<T>(
      path,
      data: data,
      options: Options(extra: {_skipAuthLogoutKey: skipAuthLogout}),
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    bool skipAuthLogout = false,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      options: Options(extra: {_skipAuthLogoutKey: skipAuthLogout}),
    );
  }

  Future<Response<T>> delete<T>(String path, {bool skipAuthLogout = false}) {
    return _dio.delete<T>(
      path,
      options: Options(extra: {_skipAuthLogoutKey: skipAuthLogout}),
    );
  }

  // --- Error normalization ---

  static ApiException _toApiException(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    // Try to extract message from common backend shapes
    String? serverMsg;
    if (data is Map) {
      serverMsg =
          (data['message'] ?? data['error'] ?? data['detail'] ?? data['msg'])
              ?.toString();
    } else if (data is String && data.trim().isNotEmpty) {
      serverMsg = data;
    }

    // Network / timeout
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return ApiException(
        statusCode: status,
        message: 'Request timed out. Try again.',
        details: data,
      );
    }

    if (e.error is SocketException) {
      return ApiException(
        statusCode: status,
        message: 'No internet connection.',
        details: data,
      );
    }

    // HTTP codes -> user-friendly messages
    switch (status) {
      case 400:
        return ApiException(
          statusCode: status,
          message: serverMsg ?? 'Bad request.',
          details: data,
        );
      case 401:
        return ApiException(
          statusCode: status,
          message: serverMsg ?? 'Invalid credentials.',
          details: data,
        );
      case 403:
        return ApiException(
          statusCode: status,
          message: serverMsg ?? 'Access denied.',
          details: data,
        );
      case 404:
        return ApiException(
          statusCode: status,
          message: serverMsg ?? 'Endpoint not found.',
          details: data,
        );
      case 409:
        return ApiException(
          statusCode: status,
          message: serverMsg ?? 'Already exists. Try a different value.',
          details: data,
        );
      case 422:
        return ApiException(
          statusCode: status,
          message: serverMsg ?? 'Validation failed. Check your inputs.',
          details: data,
        );
      default:
        if (status != null && status >= 500) {
          return ApiException(
            statusCode: status,
            message: 'Server error. Try again later.',
            details: data,
          );
        }

        return ApiException(
          statusCode: status,
          message: serverMsg ?? 'Something went wrong. Please try again.',
          details: data,
        );
    }
  }
}
