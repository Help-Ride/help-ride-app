class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.userId,
    required this.subject,
    required this.description,
    required this.status,
    required this.adminResponse,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String subject;
  final String description;
  final SupportTicketStatus status;
  final String? adminResponse;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: (json['id'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      status: SupportTicketStatusX.fromValue(json['status']),
      adminResponse: json['adminResponse']?.toString(),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  SupportTicket copyWith({
    String? id,
    String? userId,
    String? subject,
    String? description,
    SupportTicketStatus? status,
    String? adminResponse,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupportTicket(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      status: status ?? this.status,
      adminResponse: adminResponse ?? this.adminResponse,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum SupportTicketStatus { open, inProgress, resolved, closed }

extension SupportTicketStatusX on SupportTicketStatus {
  static SupportTicketStatus fromValue(dynamic value) {
    final normalized = value?.toString().trim().toLowerCase();
    switch (normalized) {
      case 'in_progress':
      case 'in-progress':
      case 'inprogress':
        return SupportTicketStatus.inProgress;
      case 'resolved':
        return SupportTicketStatus.resolved;
      case 'closed':
        return SupportTicketStatus.closed;
      case 'open':
      default:
        return SupportTicketStatus.open;
    }
  }

  String get apiValue {
    switch (this) {
      case SupportTicketStatus.inProgress:
        return 'in_progress';
      case SupportTicketStatus.resolved:
        return 'resolved';
      case SupportTicketStatus.closed:
        return 'closed';
      case SupportTicketStatus.open:
      default:
        return 'open';
    }
  }

  String get label {
    switch (this) {
      case SupportTicketStatus.inProgress:
        return 'In progress';
      case SupportTicketStatus.resolved:
        return 'Resolved';
      case SupportTicketStatus.closed:
        return 'Closed';
      case SupportTicketStatus.open:
      default:
        return 'Open';
    }
  }
}

class SupportTicketsPage {
  const SupportTicketsPage({required this.tickets, required this.nextCursor});

  final List<SupportTicket> tickets;
  final String? nextCursor;
}

DateTime _parseDate(dynamic value) {
  if (value is DateTime) return value;
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  return parsed ?? DateTime.fromMillisecondsSinceEpoch(0);
}
