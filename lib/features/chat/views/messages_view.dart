import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../controllers/chat_conversations_controller.dart';
import '../models/chat_conversation.dart';
import '../widgets/chat_conversation_tile.dart';
import 'chat_thread_view.dart';

class MessagesView extends StatefulWidget {
  const MessagesView({super.key});

  @override
  State<MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends State<MessagesView> {
  late final ChatConversationsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(ChatConversationsController());
  }

  @override
  void dispose() {
    if (Get.isRegistered<ChatConversationsController>()) {
      Get.delete<ChatConversationsController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<ThemeController>();

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Messages',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.lightText,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _controller.fetch,
                    icon: const Icon(Icons.refresh_rounded),
                    color: AppColors.lightMuted,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SearchField(onChanged: _controller.setQuery),
              const SizedBox(height: 12),
              Expanded(
                child: Obx(() {
                  if (_controller.loading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (_controller.error.value != null &&
                      _controller.conversations.isEmpty) {
                    return _EmptyState(
                      title: 'No conversations yet',
                      subtitle: 'Start a ride to connect with riders and drivers.',
                      onRetry: _controller.fetch,
                    );
                  }

                  final roleColor = theme.role.value == AppRole.driver
                      ? AppColors.driverPrimary
                      : AppColors.passengerPrimary;
                  final roleFallback = theme.role.value == AppRole.driver
                      ? 'Passenger'
                      : 'Driver';

                  final items = _controller.filtered;
                  if (items.isEmpty) {
                    return _EmptyState(
                      title: 'No matches',
                      subtitle: 'Try another name or keyword.',
                      onRetry: _controller.fetch,
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _controller.fetch,
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final conversation = items[index];
                        final label = _roleLabel(conversation, roleFallback);
                        return ChatConversationTile(
                          conversation: conversation,
                          accentColor: roleColor,
                          isDark: theme.isDark.value,
                          roleLabel: label,
                          onTap: () => _openThread(conversation),
                        );
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openThread(ChatConversation conversation) {
    _controller.setActiveConversation(conversation.id);
    Get.to(() => ChatThreadView(conversation: conversation))?.then((_) {
      _controller.setActiveConversation(null);
      _controller.fetch();
    });
  }

  String _roleLabel(ChatConversation conversation, String fallback) {
    final role = conversation.participant.role.trim();
    if (role.isEmpty) return fallback;
    return role[0].toUpperCase() + role.substring(1).toLowerCase();
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search conversations...',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFE3E8F2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFE3E8F2)),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.onRetry,
  });

  final String title;
  final String subtitle;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 42, color: AppColors.lightMuted),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.lightText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.lightMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}
