import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/chat_conversation.dart';
import '../utils/chat_formatters.dart';

class ChatConversationTile extends StatelessWidget {
  const ChatConversationTile({
    super.key,
    required this.conversation,
    required this.accentColor,
    required this.isDark,
    required this.onTap,
    required this.roleLabel,
  });

  final ChatConversation conversation;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onTap;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    final timeLabel = conversation.lastMessageAt != null
        ? chatTimeAgo(conversation.lastMessageAt!)
        : '';
    final subtitle = conversation.lastMessage.isNotEmpty
        ? conversation.lastMessage
        : 'Start a conversation';
    final hasUnread = conversation.unreadCount > 0;

    final badgeColor = accentColor;
    final avatarBg = accentColor.withOpacity(isDark ? 0.25 : 0.15);
    final tileBg =
        hasUnread ? accentColor.withOpacity(isDark ? 0.14 : 0.06) : Colors.transparent;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textMuted = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: tileBg,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: avatarBg,
                      child: Text(
                        chatInitials(conversation.participant.name),
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  if (conversation.participant.isOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1BC47D),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isDark ? AppColors.darkSurface : Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                            conversation.participant.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  hasUnread ? FontWeight.w800 : FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ),
                          if (hasUnread)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: badgeColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          if (timeLabel.isNotEmpty)
                            Text(
                              timeLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: hasUnread ? textPrimary : textMuted,
                                fontWeight:
                                    hasUnread ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (hasUnread)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(
                                Icons.mark_chat_unread_rounded,
                                size: 16,
                                color: badgeColor,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: hasUnread ? textPrimary : textMuted,
                                fontSize: 14,
                                fontWeight:
                                    hasUnread ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _RoleChip(label: roleLabel, color: accentColor),
                          if (conversation.participant.rating != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Color(0xFFFFB347),
                                  ),
                                  const SizedBox(width: 4),
                                Text(
                                  conversation.participant.rating!
                                      .toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (hasUnread)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _unreadLabel(conversation.unreadCount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _unreadLabel(int count) {
    if (count <= 0) return '';
    if (count > 9) return '9+';
    return count.toString();
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
