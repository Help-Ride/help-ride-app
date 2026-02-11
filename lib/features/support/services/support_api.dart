import 'package:dio/dio.dart';
import 'package:help_ride/shared/services/api_client.dart';
import '../models/support_app_config.dart';
import '../models/support_ticket.dart';

class SupportApi {
  SupportApi(this._client);
  final ApiClient _client;

  Future<SupportTicket> createTicket({
    required String subject,
    required String description,
  }) async {
    final res = await _client.post(
      '/support-tickets',
      data: {'subject': subject, 'description': description},
    );
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return SupportTicket.fromJson(data);
    }
    if (data is Map && data['data'] is Map<String, dynamic>) {
      return SupportTicket.fromJson(data['data']);
    }
    throw Exception('Invalid support ticket response');
  }

  Future<SupportTicketsPage> listTickets({
    SupportTicketStatus? status,
    int limit = 25,
    String? cursor,
  }) async {
    final res = await _client.get(
      '/support-tickets',
      query: {
        if (status != null) 'status': status.apiValue,
        'limit': limit.clamp(1, 100),
        if (cursor != null && cursor.trim().isNotEmpty) 'cursor': cursor.trim(),
      },
    );
    final data = res.data;
    if (data is Map) {
      final list = data['tickets'] is List
          ? data['tickets'] as List
          : (data['data'] is List
                ? data['data'] as List
                : (data['data'] is Map && data['data']['tickets'] is List
                      ? data['data']['tickets'] as List
                      : null));
      if (list != null) {
        return SupportTicketsPage(
          tickets: list
              .whereType<Map>()
              .map(
                (item) =>
                    SupportTicket.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(),
          nextCursor: _readCursor(data),
        );
      }
    }
    if (data is List) {
      return SupportTicketsPage(
        tickets: data
            .whereType<Map>()
            .map(
              (item) => SupportTicket.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(),
        nextCursor: null,
      );
    }
    return const SupportTicketsPage(
      tickets: <SupportTicket>[],
      nextCursor: null,
    );
  }

  Future<SupportTicket> getTicket(String id) async {
    final res = await _client.get('/support-tickets/$id');
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return SupportTicket.fromJson(data);
    }
    if (data is Map && data['data'] is Map<String, dynamic>) {
      return SupportTicket.fromJson(data['data']);
    }
    throw Exception('Invalid support ticket payload');
  }
}

class SupportAdminApi {
  SupportAdminApi(this._client);
  final ApiClient _client;

  Future<SupportTicketsPage> listTickets({
    required String adminApiKey,
    SupportTicketStatus? status,
    String? userId,
    int limit = 50,
    String? cursor,
  }) async {
    final res = await _client.dio.get(
      '/api/admin/support-tickets',
      queryParameters: {
        if (status != null) 'status': status.apiValue,
        if (userId != null && userId.trim().isNotEmpty) 'userId': userId.trim(),
        'limit': limit.clamp(1, 100),
        if (cursor != null && cursor.trim().isNotEmpty) 'cursor': cursor.trim(),
      },
      options: Options(headers: {'x-admin-api-key': adminApiKey}),
    );
    final data = res.data;
    if (data is Map) {
      final list = data['tickets'] is List
          ? data['tickets'] as List
          : (data['data'] is List
                ? data['data'] as List
                : (data['data'] is Map && data['data']['tickets'] is List
                      ? data['data']['tickets'] as List
                      : null));
      if (list != null) {
        return SupportTicketsPage(
          tickets: list
              .whereType<Map>()
              .map(
                (item) =>
                    SupportTicket.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(),
          nextCursor: _readCursor(data),
        );
      }
    }
    return const SupportTicketsPage(
      tickets: <SupportTicket>[],
      nextCursor: null,
    );
  }

  Future<SupportTicket> updateTicket({
    required String id,
    required String adminApiKey,
    SupportTicketStatus? status,
    String? adminResponse,
  }) async {
    final res = await _client.dio.patch(
      '/api/admin/support-tickets/$id',
      data: {
        if (status != null) 'status': status.apiValue,
        'adminResponse': adminResponse,
      },
      options: Options(headers: {'x-admin-api-key': adminApiKey}),
    );
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return SupportTicket.fromJson(data);
    }
    if (data is Map && data['data'] is Map<String, dynamic>) {
      return SupportTicket.fromJson(data['data']);
    }
    throw Exception('Invalid support ticket update payload');
  }

  Future<SupportAppConfig> getAppConfig({required String adminApiKey}) async {
    final res = await _client.dio.get(
      '/api/admin/app-config',
      options: Options(headers: {'x-admin-api-key': adminApiKey}),
    );
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return SupportAppConfig.fromJson(data);
    }
    if (data is Map && data['data'] is Map<String, dynamic>) {
      return SupportAppConfig.fromJson(data['data']);
    }
    throw Exception('Invalid app config payload');
  }

  Future<SupportAppConfig> updateAppConfig({
    required String adminApiKey,
    required bool maintenanceMode,
    String? maintenanceMessage,
  }) async {
    final res = await _client.dio.patch(
      '/api/admin/app-config',
      data: {
        'maintenanceMode': maintenanceMode,
        'maintenanceMessage': maintenanceMessage,
      },
      options: Options(headers: {'x-admin-api-key': adminApiKey}),
    );
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return SupportAppConfig.fromJson(data);
    }
    if (data is Map && data['data'] is Map<String, dynamic>) {
      return SupportAppConfig.fromJson(data['data']);
    }
    throw Exception('Invalid app config payload');
  }
}

String? _readCursor(Map data) {
  final direct = data['nextCursor'] ?? data['next_cursor'];
  if (direct is String && direct.trim().isNotEmpty) return direct;
  final nested = data['data'];
  if (nested is Map) {
    final nestedCursor = nested['nextCursor'] ?? nested['next_cursor'];
    if (nestedCursor is String && nestedCursor.trim().isNotEmpty) {
      return nestedCursor;
    }
  }
  return null;
}
