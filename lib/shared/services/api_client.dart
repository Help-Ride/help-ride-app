import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart' hide Response, FormData;

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
  static const _redacted = '[REDACTED]';

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
          _logRequest(options);
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logResponse(response);
          return handler.next(response);
        },
        onError: (e, handler) async {
          final status = e.response?.statusCode;

          _logError(e);

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

  void _logRequest(RequestOptions options) {
    final endpoint = _formatEndpoint(options);
    final query = options.queryParameters.isEmpty
        ? null
        : _sanitize(options.queryParameters);
    final body = _sanitizeBody(options.data);

    final buffer = StringBuffer()
      ..writeln('API Request: ${options.method} $endpoint');
    if (query != null) {
      buffer.writeln('Query: $query');
    }
    if (body != null) {
      buffer.writeln('Body: $body');
    }

    _safeLog(buffer.toString().trim());
  }

  void _logResponse(Response<dynamic> response) {
    final endpoint = _formatEndpoint(response.requestOptions);
    final status = response.statusCode;
    final body = _sanitize(response.data);

    final buffer = StringBuffer()
      ..writeln(
        'API Response: ${response.requestOptions.method} $endpoint',
      )
      ..writeln('Status: $status');
    if (body != null) {
      buffer.writeln('Body: $body');
    }

    _safeLog(buffer.toString().trim());
  }

  void _logError(DioException error) {
    final options = error.requestOptions;
    final endpoint = _formatEndpoint(options);
    final status = error.response?.statusCode;
    final body = _sanitize(error.response?.data);

    final buffer = StringBuffer()
      ..writeln('API Error: ${options.method} $endpoint')
      ..writeln('Status: $status');
    if (body != null) {
      buffer.writeln('Body: $body');
    }
    if (error.message != null && error.message!.trim().isNotEmpty) {
      buffer.writeln('Message: ${_sanitize(error.message)}');
    }

    _safeLog(buffer.toString().trim());
  }

  String _formatEndpoint(RequestOptions options) {
    final base = options.baseUrl;
    final path = options.path;
    if (base.isEmpty) return path;
    if (base.endsWith('/') && path.startsWith('/')) {
      return '${base.substring(0, base.length - 1)}$path';
    }
    return '$base$path';
  }

  Object? _sanitizeBody(Object? data) {
    if (data == null) return null;
    if (data is FormData) {
      return {
        'fields': Map.fromEntries(
          data.fields.map(
            (entry) => MapEntry(entry.key, _sanitize(entry.value)),
          ),
        ),
        'files': data.files
            .map((entry) => {
                  'field': entry.key,
                  'filename': entry.value.filename,
                })
            .toList(),
      };
    }
    return _sanitize(data);
  }

  Object? _sanitize(Object? value) {
    if (value == null) return null;
    if (value is Map) {
      final out = <String, dynamic>{};
      value.forEach((key, val) {
        final k = key.toString();
        if (_isSensitiveKey(k)) {
          out[k] = _redacted;
        } else {
          out[k] = _sanitize(val);
        }
      });
      return out;
    }
    if (value is List) {
      return value.map(_sanitize).toList();
    }
    if (value is String) {
      if (_looksSensitiveValue(value)) {
        return _redacted;
      }
      return value;
    }
    return value;
  }

  bool _isSensitiveKey(String key) {
    final k = key.toLowerCase();
    return k.contains('password') ||
        k.contains('token') ||
        k.contains('secret') ||
        k.contains('authorization') ||
        k.contains('apikey') ||
        k.contains('api_key') ||
        k.contains('clientsecret') ||
        k == 'key';
  }

  bool _looksSensitiveValue(String value) {
    final v = value.trim();
    if (v.isEmpty) return false;
    if (v.toLowerCase().startsWith('bearer ')) return true;
    if (v.contains('_secret_')) return true;
    if (_looksLikeJwt(v)) return true;
    final compact = !v.contains(' ') && v.length >= 40;
    if (compact && RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(v)) {
      return true;
    }
    return false;
  }

  bool _looksLikeJwt(String value) {
    final parts = value.split('.');
    if (parts.length != 3) return false;
    return parts.every(
      (part) => part.isNotEmpty && RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(part),
    );
  }

  void _safeLog(String message) {
    if (message.trim().isEmpty) return;
    debugPrint(message);
  }
}

class _Tokens {
  final String accessToken;
  final String? refreshToken;

  _Tokens({required this.accessToken, this.refreshToken});
}
