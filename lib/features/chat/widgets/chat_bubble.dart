import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/chat_message.dart';
import '../utils/chat_formatters.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.accentColor,
    required this.isDark,
  });

  final ChatMessage message;
  final bool isMine;
  final Color accentColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMine
        ? accentColor
        : (isDark ? const Color(0xFF1D2431) : Colors.white);
    final textColor = isMine
        ? Colors.white
        : (isDark ? AppColors.darkText : AppColors.lightText);
    final timeColor = isMine
        ? Colors.white70
        : (isDark ? AppColors.darkMuted : AppColors.lightMuted);
    final isSeen = isMine && message.readAt != null;
    final seenColor = isMine
        ? Colors.white70
        : (isDark ? AppColors.darkMuted : accentColor);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isMine
                    ? const Radius.circular(16)
                    : const Radius.circular(4),
                bottomRight: isMine
                    ? const Radius.circular(4)
                    : const Radius.circular(16),
              ),
              boxShadow: isMine
                  ? null
                  : [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.2)
                            : Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Text(
              message.body,
              style: TextStyle(color: textColor, fontSize: 14, height: 1.3),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                chatTimeOfDay(message.createdAt),
                style: TextStyle(
                  color: timeColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isSeen) ...[
                const SizedBox(width: 6),
                Icon(Icons.done_all_rounded, size: 12, color: seenColor),
                const SizedBox(width: 4),
                Text(
                  'Seen',
                  style: TextStyle(
                    color: seenColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
