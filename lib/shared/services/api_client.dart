import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart' hide Response;

import 'package:help_ride/shared/controllers/session_controller.dart';
import 'token_storage.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient._(this._dio, this._tokenStorage);
  final Dio _dio;
  final TokenStorage _tokenStorage;

  Dio get dio => _dio;

  static const _skipAuthLogoutKey = 'skipAuthLogout';
  static const _skipAuthRefreshKey = 'skipAuthRefresh';
  static const _authRetryKey = 'authRetry';

  Future<bool>? _refreshFuture;

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

    final client = ApiClient._(dio, tokenStorage);
    client._configureInterceptors();
    return client;
  }

  void _configureInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.getAccessToken();
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

          final skipLogout = e.requestOptions.extra[_skipAuthLogoutKey] == true;
          final skipRefresh =
              e.requestOptions.extra[_skipAuthRefreshKey] == true;
          final alreadyRetried =
              e.requestOptions.extra[_authRetryKey] == true;

          if (status == 401 && !skipLogout && !skipRefresh && !alreadyRetried) {
            final refreshed = await _refreshAccessToken();
            if (refreshed) {
              final retryResponse = await _retryRequest(e.requestOptions);
              return handler.resolve(retryResponse);
            }

            await _tokenStorage.clear();
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
  }

  Future<bool> _refreshAccessToken() async {
    if (_refreshFuture != null) {
      return _refreshFuture!;
    }
    _refreshFuture = _doRefresh();
    final result = await _refreshFuture!;
    _refreshFuture = null;
    return result;
  }

  Future<bool> _doRefresh() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.trim().isEmpty) {
      return false;
    }

    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken.trim()},
        options: Options(
          extra: {
            _skipAuthLogoutKey: true,
            _skipAuthRefreshKey: true,
          },
        ),
      );
      final data = res.data ?? {};
      final tokens = _parseTokens(data);
      if (tokens == null || tokens.accessToken.trim().isEmpty) {
        return false;
      }
      await _tokenStorage.saveAccessToken(tokens.accessToken.trim());
      if (tokens.refreshToken != null &&
          tokens.refreshToken!.trim().isNotEmpty) {
        await _tokenStorage.saveRefreshToken(tokens.refreshToken!.trim());
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Response<T>> _retryRequest<T>(RequestOptions requestOptions) async {
    final headers = Map<String, dynamic>.from(requestOptions.headers);
    final token = await _tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return _dio.request<T>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: Options(
        method: requestOptions.method,
        headers: headers,
        extra: {...requestOptions.extra, _authRetryKey: true},
        contentType: requestOptions.contentType,
        responseType: requestOptions.responseType,
        followRedirects: requestOptions.followRedirects,
        receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
        sendTimeout: requestOptions.sendTimeout,
        receiveTimeout: requestOptions.receiveTimeout,
      ),
      cancelToken: requestOptions.cancelToken,
      onReceiveProgress: requestOptions.onReceiveProgress,
      onSendProgress: requestOptions.onSendProgress,
    );
  }

  // --- Public methods ---

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    bool skipAuthLogout = false,
    bool skipAuthRefresh = false,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: query,
      options: Options(
        extra: {
          _skipAuthLogoutKey: skipAuthLogout,
          _skipAuthRefreshKey: skipAuthRefresh,
        },
      ),
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    bool skipAuthLogout = false,
    bool skipAuthRefresh = false,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      options: Options(
        extra: {
          _skipAuthLogoutKey: skipAuthLogout,
          _skipAuthRefreshKey: skipAuthRefresh,
        },
      ),
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    bool skipAuthLogout = false,
    bool skipAuthRefresh = false,
  }) {
    return _dio.patch<T>(
      path,
      data: data,
      options: Options(
        extra: {
          _skipAuthLogoutKey: skipAuthLogout,
          _skipAuthRefreshKey: skipAuthRefresh,
        },
      ),
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    bool skipAuthLogout = false,
    bool skipAuthRefresh = false,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      options: Options(
        extra: {
          _skipAuthLogoutKey: skipAuthLogout,
          _skipAuthRefreshKey: skipAuthRefresh,
        },
      ),
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    bool skipAuthLogout = false,
    bool skipAuthRefresh = false,
  }) {
    return _dio.delete<T>(
      path,
      options: Options(
        extra: {
          _skipAuthLogoutKey: skipAuthLogout,
          _skipAuthRefreshKey: skipAuthRefresh,
        },
      ),
    );
  }

  // --- Error normalization ---

  static _Tokens? _parseTokens(Map<String, dynamic> data) {
    final access = data['accessToken'];
    final refresh = data['refreshToken'];
    if (access is String && access.isNotEmpty) {
      return _Tokens(
        accessToken: access,
        refreshToken:
            refresh is String && refresh.isNotEmpty ? refresh : null,
      );
    }

    final tokens = data['tokens'];
    if (tokens is Map && tokens['accessToken'] is String) {
      final t = tokens['accessToken'] as String;
      if (t.isNotEmpty) {
        final r = tokens['refreshToken'];
        return _Tokens(
          accessToken: t,
          refreshToken: r is String && r.isNotEmpty ? r : null,
        );
      }
    }

    return null;
  }

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

class _Tokens {
  final String accessToken;
  final String? refreshToken;

  _Tokens({required this.accessToken, this.refreshToken});
}
