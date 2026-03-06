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
    final routeSummary = conversation.tripSummary?.trim() ?? '';
    final rideReference = conversation.rideReference?.trim().isNotEmpty == true
        ? conversation.rideReference!.trim()
        : chatRideReference(conversation.rideId);
    final rideStatus = chatRideStatus(conversation.rideStatus ?? '');
    final rideTimeLabel = conversation.tripTimeLabel?.trim() ?? '';
    final priceLabel = conversation.ridePricePerSeat == null
        ? ''
        : '\$${chatCurrencyLabel(conversation.ridePricePerSeat!)}/seat';
    final subtitle = conversation.lastMessage.isNotEmpty
        ? conversation.lastMessage
        : 'Start a conversation';
    final hasUnread = conversation.unreadCount > 0;

    final badgeColor = accentColor;
    final avatarBg = accentColor.withValues(alpha: isDark ? 0.25 : 0.15);
    final tileBg = hasUnread
        ? accentColor.withValues(alpha: isDark ? 0.14 : 0.06)
        : Colors.transparent;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textMuted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final isOnline = conversation.participant.isOnline;

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
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isOnline
                              ? const Color(0xFF1BC47D)
                              : (isDark
                                    ? const Color(0xFF4B5563)
                                    : const Color(0xFFB7C0CF)),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkSurface
                                : Colors.white,
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
                                fontWeight: hasUnread
                                    ? FontWeight.w800
                                    : FontWeight.w700,
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
                                fontWeight: hasUnread
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      if (routeSummary.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.route_rounded,
                              size: 15,
                              color: accentColor,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                routeSummary,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
                                fontWeight: hasUnread
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _RoleChip(label: roleLabel, color: accentColor),
                          _StatusChip(isOnline: isOnline),
                          if (rideReference.isNotEmpty)
                            _MetaChip(
                              label: rideReference,
                              background: accentColor.withValues(
                                alpha: isDark ? 0.2 : 0.1,
                              ),
                              foreground: accentColor,
                              icon: Icons.directions_car_filled_outlined,
                            ),
                          if (rideTimeLabel.isNotEmpty)
                            _MetaChip(
                              label: rideTimeLabel,
                              background: isDark
                                  ? const Color(0xFF1F2937)
                                  : const Color(0xFFF1F5F9),
                              foreground: textMuted,
                              icon: Icons.schedule_rounded,
                            ),
                          if (priceLabel.isNotEmpty)
                            _MetaChip(
                              label: priceLabel,
                              background: isDark
                                  ? const Color(0xFF13232E)
                                  : const Color(0xFFE8F7F0),
                              foreground: const Color(0xFF179C5E),
                              icon: Icons.attach_money_rounded,
                            ),
                          if (rideStatus.isNotEmpty)
                            _MetaChip(
                              label: rideStatus,
                              background: isDark
                                  ? const Color(0xFF242B39)
                                  : const Color(0xFFEFF2F6),
                              foreground: textMuted,
                              icon: Icons.local_offer_outlined,
                            ),
                          if (conversation.participant.rating != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
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
                        ],
                      ),
                    ],
                  ),
                ),
                if (hasUnread)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
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
        color: color.withValues(alpha: 0.12),
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isOnline
        ? const Color(0xFFE7F8EF)
        : (isDark ? const Color(0xFF1F2937) : const Color(0xFFEFF2F6));
    final fg = isOnline
        ? const Color(0xFF179C5E)
        : (isDark ? const Color(0xFF9AA3B2) : const Color(0xFF6B7280));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isOnline
                  ? const Color(0xFF1BC47D)
                  : (isDark
                        ? const Color(0xFF9AA3B2)
                        : const Color(0xFF6B7280)),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
