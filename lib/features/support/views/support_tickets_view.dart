import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:help_ride/core/theme/app_colors.dart';
import 'package:help_ride/core/theme/theme_controller.dart';
import 'package:help_ride/shared/utils/input_validators.dart';
import 'package:help_ride/shared/widgets/app_input_decoration.dart';
import '../controllers/support_tickets_controller.dart';
import '../models/support_ticket.dart';
import '../routes/support_routes.dart';

class SupportTicketsView extends StatefulWidget {
  const SupportTicketsView({super.key});

  @override
  State<SupportTicketsView> createState() => _SupportTicketsViewState();
}

class _SupportTicketsViewState extends State<SupportTicketsView> {
  late final SupportTicketsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<SupportTicketsController>()
        ? Get.find<SupportTicketsController>()
        : Get.put(SupportTicketsController());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<ThemeController>();
    final isDark = theme.isDark.value;

    return Scaffold(
      backgroundColor: _surfaceBg(isDark),
      appBar: AppBar(
        backgroundColor: _surfaceBg(isDark),
        elevation: 0,
        title: Text(
          'Help Center',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: _textPrimary(isDark),
          ),
        ),
        iconTheme: IconThemeData(color: _textPrimary(isDark)),
        actions: [
          IconButton(
            onPressed: () => _openCreateSheet(context),
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'New ticket',
          ),
        ],
      ),
      body: Obx(() {
        final loading = _controller.loading.value;
        final error = _controller.error.value;
        final tickets = _controller.tickets;

        if (loading && tickets.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (error != null && tickets.isEmpty) {
          return _ErrorState(
            message: error,
            onRetry: () => _controller.fetchTickets(reset: true),
            isDark: isDark,
          );
        }

        return Column(
          children: [
            _FilterChips(
              selected: _controller.statusFilter.value,
              isDark: isDark,
              onSelected: (status) => _controller.setStatusFilter(status),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _controller.fetchTickets(reset: true),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                  itemCount:
                      tickets.length +
                      (_controller.nextCursor.value != null ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index >= tickets.length) {
                      return _LoadMoreButton(
                        isDark: isDark,
                        isLoading: _controller.loadingMore.value,
                        onPressed: () => _controller.loadMore(),
                      );
                    }
                    final ticket = tickets[index];
                    return _TicketCard(
                      ticket: ticket,
                      isDark: isDark,
                      onTap: () => Get.toNamed(
                        SupportRoutes.ticketDetail,
                        arguments: {'id': ticket.id, 'ticket': ticket},
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _openCreateSheet(BuildContext context) async {
    final subjectCtrl = TextEditingController();
    final descriptionCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final isDark = Get.find<ThemeController>().isDark.value;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surfaceCard(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            16,
            18,
            16 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _divider(isDark),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'New support ticket',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary(isDark),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (Navigator.of(sheetContext).canPop()) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                      icon: const Icon(Icons.close),
                      color: _mutedText(isDark),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _InputField(
                  controller: subjectCtrl,
                  label: 'Subject',
                  validator: (value) => InputValidators.minLength(
                    value ?? '',
                    fieldLabel: 'Subject',
                    minChars: 3,
                  ),
                ),
                const SizedBox(height: 12),
                _InputField(
                  controller: descriptionCtrl,
                  label: 'Describe the issue',
                  maxLines: 4,
                  validator: (value) => InputValidators.minLength(
                    value ?? '',
                    fieldLabel: 'Description',
                    minChars: 10,
                  ),
                ),
                const SizedBox(height: 16),
                Obx(() {
                  final saving = _controller.creating.value;
                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              if (!(formKey.currentState?.validate() ??
                                  false)) {
                                return;
                              }
                              final subject = subjectCtrl.text.trim();
                              final description = descriptionCtrl.text.trim();
                              try {
                                await _controller.createTicket(
                                  subject: subject,
                                  description: description,
                                );
                                if (Navigator.of(sheetContext).canPop()) {
                                  Navigator.of(sheetContext).pop();
                                }
                              } catch (e) {
                                _showSnack(context, e.toString());
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.passengerPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Submit ticket',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selected,
    required this.isDark,
    required this.onSelected,
  });

  final SupportTicketStatus? selected;
  final bool isDark;
  final ValueChanged<SupportTicketStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    final filters = <SupportTicketStatus?>[
      null,
      SupportTicketStatus.open,
      SupportTicketStatus.inProgress,
      SupportTicketStatus.resolved,
      SupportTicketStatus.closed,
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Row(
        children: filters.map((status) {
          final isActive = status == selected;
          final label = status?.label ?? 'All';
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isActive,
              onSelected: (_) => onSelected(status),
              selectedColor: AppColors.passengerPrimary.withOpacity(0.18),
              labelStyle: TextStyle(
                color: isActive
                    ? AppColors.passengerPrimary
                    : _mutedText(isDark),
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: _surfaceCard(isDark),
              side: BorderSide(color: _cardBorder(isDark)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.ticket,
    required this.isDark,
    required this.onTap,
  });

  final SupportTicket ticket;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final updated = _formatDate(ticket.updatedAt);
    final response = (ticket.adminResponse ?? '').trim();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
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
                    ticket.subject.isNotEmpty
                        ? ticket.subject
                        : 'Support ticket',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: _textPrimary(isDark),
                    ),
                  ),
                ),
                _StatusPill(status: ticket.status, isDark: isDark),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              ticket.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: _mutedText(isDark)),
            ),
            if (response.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Response: $response',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _textPrimary(isDark),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Updated $updated',
              style: TextStyle(color: _mutedText(isDark), fontSize: 12),
            ),
          ],
        ),
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

class _LoadMoreButton extends StatelessWidget {
  const _LoadMoreButton({
    required this.isDark,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isDark;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                'Load more',
                style: TextStyle(
                  color: _textPrimary(isDark),
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
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

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: appInputDecoration(context, labelText: label, radius: 14),
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

Color _divider(bool isDark) =>
    isDark ? const Color(0xFF2A3140) : const Color(0xFFE6EAF2);

Color _mutedText(bool isDark) =>
    isDark ? AppColors.darkMuted : AppColors.lightMuted;

Color _textPrimary(bool isDark) =>
    isDark ? AppColors.darkText : AppColors.lightText;

Color _chipNeutralBg(bool isDark) =>
    isDark ? const Color(0xFF1E222D) : const Color(0xFFF1F3F7);
