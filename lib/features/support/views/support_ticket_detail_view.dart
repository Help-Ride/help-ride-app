import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:help_ride/core/theme/app_colors.dart';
import 'package:help_ride/core/theme/theme_controller.dart';
import '../controllers/support_tickets_controller.dart';
import '../models/support_ticket.dart';

class SupportTicketDetailView extends StatefulWidget {
  const SupportTicketDetailView({super.key});

  @override
  State<SupportTicketDetailView> createState() =>
      _SupportTicketDetailViewState();
}

class _SupportTicketDetailViewState extends State<SupportTicketDetailView> {
  late final SupportTicketsController _controller;
  SupportTicket? _ticket;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<SupportTicketsController>()
        ? Get.find<SupportTicketsController>()
        : Get.put(SupportTicketsController());
    _hydrateFromArgs();
    _fetchTicket();
  }

  void _hydrateFromArgs() {
    final args = Get.arguments;
    if (args is Map) {
      final ticket = args['ticket'];
      if (ticket is SupportTicket) {
        _ticket = ticket;
      }
    }
  }

  Future<void> _fetchTicket() async {
    final id = _ticket?.id ?? _readIdFromArgs();
    if (id == null || id.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final ticket = await _controller.getTicket(id.trim());
    if (!mounted) return;
    setState(() {
      _ticket = ticket ?? _ticket;
      _loading = false;
      _error = ticket == null ? _controller.error.value : null;
    });
  }

  String? _readIdFromArgs() {
    final args = Get.arguments;
    if (args is Map) {
      final id = args['id'];
      if (id != null) return id.toString();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Get.find<ThemeController>().isDark.value;

    return Scaffold(
      backgroundColor: _surfaceBg(isDark),
      appBar: AppBar(
        title: Text(
          'Ticket details',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: _textPrimary(isDark),
          ),
        ),
        backgroundColor: _surfaceBg(isDark),
        elevation: 0,
        iconTheme: IconThemeData(color: _textPrimary(isDark)),
      ),
      body: _loading && _ticket == null
          ? const Center(child: CircularProgressIndicator())
          : _ticket == null
              ? _EmptyState(
                  message: _error ?? 'Ticket not found.',
                  onRetry: _fetchTicket,
                  isDark: isDark,
                )
              : RefreshIndicator(
                  onRefresh: _fetchTicket,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                    children: [
                      _DetailCard(
                        title: _ticket!.subject,
                        status: _ticket!.status,
                        description: _ticket!.description,
                        createdAt: _ticket!.createdAt,
                        updatedAt: _ticket!.updatedAt,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      _ResponseCard(
                        response: _ticket!.adminResponse,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.title,
    required this.status,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.isDark,
  });

  final String title;
  final SupportTicketStatus status;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final updated = _formatDate(updatedAt);
    final created = _formatDate(createdAt);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceCard(isDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title.isNotEmpty ? title : 'Support ticket',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: _textPrimary(isDark),
                  ),
                ),
              ),
              _StatusPill(status: status, isDark: isDark),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(color: _textPrimary(isDark), height: 1.4),
          ),
          const SizedBox(height: 14),
          _DetailRow(label: 'Created', value: created, isDark: isDark),
          _DetailRow(label: 'Updated', value: updated, isDark: isDark),
        ],
      ),
    );
  }
}

class _ResponseCard extends StatelessWidget {
  const _ResponseCard({required this.response, required this.isDark});

  final String? response;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final text = (response ?? '').trim();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceCard(isDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin response',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: _textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            text.isNotEmpty ? text : 'No response yet.',
            style: TextStyle(color: _mutedText(isDark), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.isDark});

  final SupportTicketStatus status;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle(status, isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: style.color,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: _mutedText(isDark), fontSize: 13),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: _textPrimary(isDark),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.message,
    required this.onRetry,
    required this.isDark,
  });

  final String message;
  final VoidCallback onRetry;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.support_agent, color: _mutedText(isDark), size: 32),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: _mutedText(isDark)),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.passengerPrimary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusStyle {
  const _StatusStyle({required this.color, required this.background});

  final Color color;
  final Color background;
}

_StatusStyle _statusStyle(SupportTicketStatus status, bool isDark) {
  switch (status) {
    case SupportTicketStatus.inProgress:
      return _StatusStyle(
        color: const Color(0xFFAA6A00),
        background: isDark ? const Color(0xFF3A2C12) : const Color(0xFFFFF4E5),
      );
    case SupportTicketStatus.resolved:
      return _StatusStyle(
        color: AppColors.passengerPrimary,
        background: isDark ? const Color(0xFF14382B) : const Color(0xFFE8FAF3),
      );
    case SupportTicketStatus.closed:
      return _StatusStyle(
        color: _mutedText(isDark),
        background: _chipNeutralBg(isDark),
      );
    case SupportTicketStatus.open:
    default:
      return _StatusStyle(
        color: AppColors.driverPrimary,
        background: isDark ? const Color(0xFF162940) : const Color(0xFFEAF2FF),
      );
  }
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final mm = local.month.toString().padLeft(2, '0');
  final dd = local.day.toString().padLeft(2, '0');
  return '$mm/$dd/${local.year}';
}

Color _surfaceBg(bool isDark) => isDark ? AppColors.darkBg : AppColors.lightBg;

Color _surfaceCard(bool isDark) =>
    isDark ? AppColors.darkSurface : Colors.white;

Color _cardBorder(bool isDark) =>
    isDark ? const Color(0xFF232836) : const Color(0xFFE6EAF2);

Color _mutedText(bool isDark) =>
    isDark ? AppColors.darkMuted : AppColors.lightMuted;

Color _textPrimary(bool isDark) =>
    isDark ? AppColors.darkText : AppColors.lightText;

Color _chipNeutralBg(bool isDark) =>
    isDark ? const Color(0xFF1E222D) : const Color(0xFFF1F3F7);
