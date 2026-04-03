import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:help_ride/core/theme/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
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
  static const _supportEmail = 'support@help-ride.app';
  late final SupportTicketsController _controller;
  late final String _initialTopic;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<SupportTicketsController>()
        ? Get.find<SupportTicketsController>()
        : Get.put(SupportTicketsController());
    _initialTopic = _readInitialTopic();
  }

  String _readInitialTopic() {
    final args = Get.arguments;
    if (args is Map) {
      final topic = args['topic']?.toString().trim().toLowerCase();
      if (topic == 'safety' || topic == 'support') {
        return topic!;
      }
    }
    return 'support';
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
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _controller.fetchTickets(reset: true),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                  children: [
                    _SupportQuickHelpCard(
                      isDark: isDark,
                      topic: _initialTopic,
                      supportEmail: _supportEmail,
                      onCopyEmail: () async {
                        await Clipboard.setData(
                          const ClipboardData(text: _supportEmail),
                        );
                        if (!context.mounted) return;
                        _showSnack(context, 'Support email copied.');
                      },
                    ),
                    const SizedBox(height: 14),
                    _FilterChips(
                      selected: _controller.statusFilter.value,
                      isDark: isDark,
                      onSelected: (status) =>
                          _controller.setStatusFilter(status),
                    ),
                    const SizedBox(height: 10),
                    if (tickets.isEmpty)
                      _EmptyTicketsState(isDark: isDark)
                    else
                      ...List.generate(tickets.length, (index) {
                        final ticket = tickets[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom:
                                index == tickets.length - 1 &&
                                    _controller.nextCursor.value == null
                                ? 0
                                : 12,
                          ),
                          child: _TicketCard(
                            ticket: ticket,
                            isDark: isDark,
                            onTap: () => Get.toNamed(
                              SupportRoutes.ticketDetail,
                              arguments: {'id': ticket.id, 'ticket': ticket},
                            ),
                          ),
                        );
                      }),
                    if (_controller.nextCursor.value != null)
                      _LoadMoreButton(
                        isDark: isDark,
                        isLoading: _controller.loadingMore.value,
                        onPressed: () => _controller.loadMore(),
                      ),
                  ],
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
    _SelectedSupportAttachment? selectedAttachment;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surfaceCard(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> pickAttachment() async {
              final picked = await _pickSupportAttachment();
              if (!sheetContext.mounted || picked == null) return;
              setSheetState(() => selectedAttachment = picked);
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                16,
                18,
                16 + MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
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
                      const SizedBox(height: 12),
                      _SupportAttachmentPicker(
                        isDark: isDark,
                        attachment: selectedAttachment,
                        onPick: pickAttachment,
                        onRemove: selectedAttachment == null
                            ? null
                            : () => setSheetState(
                                () => selectedAttachment = null,
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
                                    final description = descriptionCtrl.text
                                        .trim();
                                    try {
                                      await _controller.createTicket(
                                        subject: subject,
                                        description: description,
                                        attachmentFilePath:
                                            selectedAttachment?.path,
                                        attachmentFileName:
                                            selectedAttachment?.fileName,
                                        attachmentMimeType:
                                            selectedAttachment?.mimeType,
                                      );
                                      if (!mounted || !sheetContext.mounted) {
                                        return;
                                      }
                                      if (Navigator.of(sheetContext).canPop()) {
                                        Navigator.of(sheetContext).pop();
                                      }
                                    } catch (e) {
                                      if (!mounted) return;
                                      _showSnack(
                                        context,
                                        e.toString().replaceFirst(
                                          'Exception: ',
                                          '',
                                        ),
                                      );
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
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<_SelectedSupportAttachment?> _pickSupportAttachment() async {
    final source = await _promptSupportAttachmentSource();
    if (!mounted || source == null) return null;

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      imageQuality: 86,
      maxWidth: 1600,
    );
    if (!mounted || image == null) return null;

    final fileName = image.name.trim().isNotEmpty
        ? image.name.trim()
        : image.path.split('/').last;
    return _SelectedSupportAttachment(
      path: image.path,
      fileName: fileName,
      mimeType: lookupMimeType(image.path) ?? 'image/jpeg',
    );
  }

  Future<ImageSource?> _promptSupportAttachmentSource() {
    final isDark = Get.find<ThemeController>().isDark.value;
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add image',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Attach a screenshot or photo that helps explain the issue.',
                  style: TextStyle(color: _mutedText(isDark), height: 1.35),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Take photo'),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(ImageSource.camera),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose existing image'),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(ImageSource.gallery),
                ),
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

class _SupportQuickHelpCard extends StatelessWidget {
  const _SupportQuickHelpCard({
    required this.isDark,
    required this.topic,
    required this.supportEmail,
    required this.onCopyEmail,
  });

  final bool isDark;
  final String topic;
  final String supportEmail;
  final VoidCallback onCopyEmail;

  @override
  Widget build(BuildContext context) {
    final sections = topic == 'safety'
        ? const [_FaqSection.safety, _FaqSection.support]
        : const [_FaqSection.support, _FaqSection.safety];

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
            'Quick help',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Find answers before opening a ticket. If you still need help, create a support ticket below.',
            style: TextStyle(color: _mutedText(isDark), height: 1.35),
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < sections.length; i++) ...[
            _FaqSectionCard(section: sections[i], isDark: isDark),
            if (i != sections.length - 1) const SizedBox(height: 12),
          ],
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _chipNeutralBg(isDark),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.mail_outline, color: _textPrimary(isDark), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    supportEmail,
                    style: TextStyle(
                      color: _textPrimary(isDark),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(onPressed: onCopyEmail, child: const Text('Copy')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqSectionCard extends StatelessWidget {
  const _FaqSectionCard({required this.section, required this.isDark});

  final _FaqSection section;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _chipNeutralBg(isDark),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
            child: Row(
              children: [
                Icon(section.icon, color: section.iconColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    section.title,
                    style: TextStyle(
                      color: _textPrimary(isDark),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (final item in section.items)
            Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                iconColor: _textPrimary(isDark),
                collapsedIconColor: _mutedText(isDark),
                title: Text(
                  item.question,
                  style: TextStyle(
                    color: _textPrimary(isDark),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item.answer,
                      style: TextStyle(
                        color: _mutedText(isDark),
                        height: 1.4,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyTicketsState extends StatelessWidget {
  const _EmptyTicketsState({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceCard(isDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No tickets yet',
            style: TextStyle(
              color: _textPrimary(isDark),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'If the FAQs do not solve the issue, use the add button in the top-right corner to contact HelpRide support.',
            style: TextStyle(color: _mutedText(isDark), height: 1.35),
          ),
        ],
      ),
    );
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
              selectedColor: AppColors.passengerPrimary.withValues(alpha: 0.18),
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
            if ((ticket.attachmentUrl ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.image_outlined,
                    color: _mutedText(isDark),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Image attached',
                    style: TextStyle(
                      color: _textPrimary(isDark),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
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

class _SupportAttachmentPicker extends StatelessWidget {
  const _SupportAttachmentPicker({
    required this.isDark,
    required this.attachment,
    required this.onPick,
    required this.onRemove,
  });

  final bool isDark;
  final _SelectedSupportAttachment? attachment;
  final VoidCallback onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceCard(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Screenshot or photo (optional)',
                  style: TextStyle(
                    color: _textPrimary(isDark),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onPick,
                icon: Icon(
                  attachment == null
                      ? Icons.add_photo_alternate_outlined
                      : Icons.edit_outlined,
                  size: 18,
                ),
                label: Text(attachment == null ? 'Add image' : 'Change'),
              ),
            ],
          ),
          Text(
            'Include one image that shows the problem clearly.',
            style: TextStyle(
              color: _mutedText(isDark),
              fontSize: 12,
              height: 1.35,
            ),
          ),
          if (attachment != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(attachment!.path),
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    attachment!.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _textPrimary(isDark),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onRemove != null)
                  TextButton(onPressed: onRemove, child: const Text('Remove')),
              ],
            ),
          ],
        ],
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

class _FaqItem {
  const _FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;
}

class _FaqSection {
  const _FaqSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final List<_FaqItem> items;

  static const support = _FaqSection(
    title: 'Help & support FAQs',
    icon: Icons.support_agent_outlined,
    iconColor: AppColors.passengerPrimary,
    items: [
      _FaqItem(
        question: 'How do I contact HelpRide support?',
        answer:
            'Open a support ticket from this screen using the add button. Include the ride, booking, or payment details so the team can investigate faster.',
      ),
      _FaqItem(
        question: 'What should I include in a support ticket?',
        answer:
            'Add a short subject, what happened, when it happened, and any booking or ride details you have. If money or safety is involved, mention that in the first line.',
      ),
      _FaqItem(
        question: 'When should I use a ticket instead of chat?',
        answer:
            'Use chat for live ride coordination with the other user. Use HelpRide support tickets for refunds, policy concerns, account issues, or anything that needs staff review.',
      ),
    ],
  );

  static const safety = _FaqSection(
    title: 'Emergency & safety FAQs',
    icon: Icons.shield_outlined,
    iconColor: AppColors.driverPrimary,
    items: [
      _FaqItem(
        question: 'What should I do in an emergency during a trip?',
        answer:
            'If there is immediate danger, call 911 or your local emergency services first. After you are safe, open a HelpRide support ticket with the trip details so the incident can be reviewed.',
      ),
      _FaqItem(
        question: 'Does HelpRide store an emergency contact in the app?',
        answer:
            'Not currently. HelpRide does not keep a dedicated in-app emergency contact, so contact emergency services and someone you trust directly if urgent help is needed.',
      ),
      _FaqItem(
        question:
            'What safety details should I send to support after an incident?',
        answer:
            'Share the ride date, pickup and drop-off area, the other person involved, and a clear summary of what happened. Add whether police, medical, or roadside help was contacted.',
      ),
    ],
  );
}

class _SelectedSupportAttachment {
  const _SelectedSupportAttachment({
    required this.path,
    required this.fileName,
    required this.mimeType,
  });

  final String path;
  final String fileName;
  final String mimeType;
}
