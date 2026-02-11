import 'package:get/get.dart';
import '../bindings/support_tickets_binding.dart';
import '../views/support_ticket_detail_view.dart';
import '../views/support_tickets_view.dart';

class SupportRoutes {
  static const tickets = '/support/tickets';
  static const ticketDetail = '/support/tickets/detail';

  static final pages = [
    GetPage(
      name: tickets,
      page: () => const SupportTicketsView(),
      binding: SupportTicketsBinding(),
    ),
    GetPage(
      name: ticketDetail,
      page: () => const SupportTicketDetailView(),
      binding: SupportTicketsBinding(),
    ),
  ];
}
