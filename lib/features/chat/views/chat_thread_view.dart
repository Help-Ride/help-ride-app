import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../controllers/chat_thread_controller.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../widgets/chat_bubble.dart';

class ChatThreadView extends StatefulWidget {
  const ChatThreadView({super.key, required this.conversation});

  final ChatConversation conversation;

  @override
  State<ChatThreadView> createState() => _ChatThreadViewState();
}

class _ChatThreadViewState extends State<ChatThreadView> {
  late final ChatThreadController _controller;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Worker? _messageWorker;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(
      ChatThreadController(conversation: widget.conversation),
      tag: widget.conversation.id,
    );
    _messageWorker = ever<List<ChatMessage>>(
      _controller.messages,
      (_) => _scrollToBottom(),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _messageWorker?.dispose();
    if (Get.isRegistered<ChatThreadController>(tag: widget.conversation.id)) {
      Get.delete<ChatThreadController>(tag: widget.conversation.id);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<ThemeController>();
    final roleColor = theme.role.value == AppRole.driver
        ? AppColors.driverPrimary
        : AppColors.passengerPrimary;

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: _ChatHeader(
        conversation: widget.conversation,
        accentColor: roleColor,
      ),
      body: Column(
        children: [
          _TripSummaryCard(conversation: widget.conversation, accentColor: roleColor),
          Expanded(
            child: Obx(() {
              if (_controller.loading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_controller.error.value != null && _controller.messages.isEmpty) {
                return Center(
                  child: Text(
                    'Unable to load messages.',
                    style: TextStyle(color: Colors.black.withOpacity(0.6)),
                  ),
                );
              }

              final messages = _controller.messages;
              if (messages.isEmpty) {
                return const Center(
                  child: Text(
                    'Say hello to start the chat.',
                    style: TextStyle(color: AppColors.lightMuted),
                  ),
                );
              }

              return ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                itemCount: messages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  return ChatBubble(
                    message: msg,
                    isMine: _isMine(msg),
                    accentColor: roleColor,
                    isDark: theme.isDark.value,
                  );
                },
              );
            }),
          ),
          _Composer(
            controller: _textController,
            accentColor: roleColor,
            onChanged: (value) => _controller.draft.value = value,
            onSend: _handleSend,
          ),
        ],
      ),
    );
  }

  bool _isMine(ChatMessage msg) {
    final me = _controller.currentUserId;
    if (me.isEmpty) return msg.senderRole == _controller.currentRole;
    return msg.senderId == me;
  }

  void _handleSend() {
    _controller.draft.value = _textController.text;
    _controller.sendCurrent();
    _textController.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }
}

class _ChatHeader extends StatelessWidget implements PreferredSizeWidget {
  const _ChatHeader({required this.conversation, required this.accentColor});

  final ChatConversation conversation;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        color: AppColors.lightText,
        onPressed: () => Get.back(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: accentColor.withOpacity(0.15),
            child: Text(
              conversation.participant.name.isNotEmpty
                  ? conversation.participant.name[0].toUpperCase()
                  : 'U',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversation.participant.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: conversation.participant.isOnline
                            ? const Color(0xFF1BC47D)
                            : AppColors.lightMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      conversation.participant.isOnline ? 'Online' : 'Offline',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.lightMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.call_outlined),
          color: AppColors.lightMuted,
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.more_vert),
          color: AppColors.lightMuted,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}

class _TripSummaryCard extends StatelessWidget {
  const _TripSummaryCard({required this.conversation, required this.accentColor});

  final ChatConversation conversation;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final summary = conversation.tripSummary?.trim() ?? '';
    final time = conversation.tripTimeLabel?.trim() ?? '';
    if (summary.isEmpty && time.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.route, color: accentColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upcoming Trip',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.lightText,
                    ),
                  ),
                  if (summary.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        summary,
                        style: const TextStyle(color: AppColors.lightMuted),
                      ),
                    ),
                ],
              ),
            ),
            if (time.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: AppColors.lightMuted),
                  const SizedBox(width: 4),
                  Text(
                    time,
                    style: const TextStyle(color: AppColors.lightMuted),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.accentColor,
    required this.onChanged,
    required this.onSend,
  });

  final TextEditingController controller;
  final Color accentColor;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE3E8F2))),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: const Color(0xFFF3F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onSend,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
