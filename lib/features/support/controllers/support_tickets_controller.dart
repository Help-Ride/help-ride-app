import 'package:get/get.dart';
import 'package:help_ride/shared/services/api_client.dart';
import '../models/support_ticket.dart';
import '../services/support_api.dart';

class SupportTicketsController extends GetxController {
  late final SupportApi _api;

  final tickets = <SupportTicket>[].obs;
  final loading = false.obs;
  final loadingMore = false.obs;
  final creating = false.obs;
  final error = RxnString();
  final nextCursor = RxnString();
  final statusFilter = Rxn<SupportTicketStatus>();

  @override
  Future<void> onInit() async {
    super.onInit();
    final client = await ApiClient.create();
    _api = SupportApi(client);
    await fetchTickets();
  }

  Future<void> fetchTickets({bool reset = true}) async {
    if (loading.value) return;
    loading.value = true;
    error.value = null;
    if (reset) {
      tickets.clear();
      nextCursor.value = null;
    }
    try {
      final page = await _api.listTickets(
        status: statusFilter.value,
        limit: 25,
        cursor: reset ? null : nextCursor.value,
      );
      if (reset) {
        tickets.assignAll(page.tickets);
      } else {
        tickets.addAll(page.tickets);
      }
      nextCursor.value = page.nextCursor;
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (loadingMore.value) return;
    final cursor = nextCursor.value;
    if (cursor == null || cursor.trim().isEmpty) return;
    loadingMore.value = true;
    error.value = null;
    try {
      final page = await _api.listTickets(
        status: statusFilter.value,
        limit: 25,
        cursor: cursor,
      );
      tickets.addAll(page.tickets);
      nextCursor.value = page.nextCursor;
    } catch (e) {
      error.value = e.toString();
    } finally {
      loadingMore.value = false;
    }
  }

  Future<SupportTicket?> createTicket({
    required String subject,
    required String description,
  }) async {
    if (creating.value) return null;
    creating.value = true;
    error.value = null;
    try {
      final ticket = await _api.createTicket(
        subject: subject,
        description: description,
      );
      tickets.insert(0, ticket);
      return ticket;
    } catch (e) {
      error.value = e.toString();
      rethrow;
    } finally {
      creating.value = false;
    }
  }

  Future<SupportTicket?> getTicket(String id) async {
    try {
      final ticket = await _api.getTicket(id);
      _replaceTicket(ticket);
      return ticket;
    } catch (e) {
      error.value = e.toString();
      return null;
    }
  }

  void setStatusFilter(SupportTicketStatus? status) {
    statusFilter.value = status;
    fetchTickets(reset: true);
  }

  void _replaceTicket(SupportTicket ticket) {
    final idx = tickets.indexWhere((item) => item.id == ticket.id);
    if (idx == -1) return;
    tickets[idx] = ticket;
  }
}
