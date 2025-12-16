import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart' hide Response;
import 'package:help_ride/shared/controllers/session_controller.dart';
import 'token_storage.dart';

class ApiClient {
  ApiClient._(this._dio);
  final Dio _dio;

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
          print('API Error: ${e.response?.statusCode} ${e.response?.data}');
          if (e.response?.statusCode == 401) {
            await tokenStorage.clear();
            // avoid import loops by using Get if available
            if (Get.isRegistered<SessionController>()) {
              await Get.find<SessionController>().logout();
            }
            Get.offAllNamed('/login');
          }
          return handler.next(e);
        },
      ),
    );

    return ApiClient._(dio);
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) {
    return _dio.get<T>(path, queryParameters: query);
  }

  Future<Response<T>> post<T>(String path, {Object? data}) {
    return _dio.post<T>(path, data: data);
  }

  Future<Response<T>> patch<T>(String path, {Object? data}) {
    return _dio.patch<T>(path, data: data);
  }

  Future<Response<T>> delete<T>(String path) {
    return _dio.delete<T>(path);
  }
}
