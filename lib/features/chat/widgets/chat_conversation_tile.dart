import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/user_avatar.dart';
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
    final moderationLabel = conversation.blockedByMe
        ? 'Blocked'
        : (conversation.blockedByOtherUser ? 'Unavailable' : '');
    final paymentLabel = conversation.paymentRequired ? 'Payment required' : '';
    final routeLabel = routeSummary.isNotEmpty ? routeSummary : rideReference;
    final avatarUrl = (conversation.participant.avatarUrl ?? '').trim();

    final badgeColor = accentColor;
    final avatarBg = accentColor.withValues(alpha: isDark ? 0.22 : 0.14);
    final tileBg = hasUnread
        ? accentColor.withValues(alpha: isDark ? 0.12 : 0.05)
        : (isDark ? AppColors.darkSurface : Colors.white);
    final tileBorder = isDark
        ? const Color(0xFF232836)
        : const Color(0xFFE6EAF2);
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textMuted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final isOnline = conversation.participant.isOnline;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: tileBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tileBorder),
            boxShadow: isDark
                ? []
                : const [
                    BoxShadow(
                      blurRadius: 18,
                      offset: Offset(0, 10),
                      color: Color(0x08000000),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    UserAvatar(
                      name: conversation.participant.name,
                      avatarUrl: avatarUrl,
                      radius: 26,
                      backgroundColor: avatarBg,
                      foregroundColor: accentColor,
                      textStyle: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    Positioned(
                      bottom: 1,
                      right: 1,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              conversation.participant.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: hasUnread
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                                color: textPrimary,
                              ),
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
                      if (routeLabel.isNotEmpty) ...[
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
                                routeLabel,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: hasUnread ? textPrimary : textMuted,
                          fontSize: 14,
                          fontWeight: hasUnread
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _RoleChip(label: roleLabel, color: accentColor),
                          if (paymentLabel.isNotEmpty)
                            _MetaChip(
                              label: paymentLabel,
                              background: isDark
                                  ? const Color(0xFF332714)
                                  : const Color(0xFFFFF4E6),
                              foreground: const Color(0xFFB96A12),
                              icon: Icons.lock_outline_rounded,
                            ),
                          if (moderationLabel.isNotEmpty)
                            _MetaChip(
                              label: moderationLabel,
                              background: isDark
                                  ? const Color(0xFF332126)
                                  : const Color(0xFFFCEBEC),
                              foreground: const Color(0xFFC5394D),
                              icon: Icons.shield_outlined,
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
                        ],
                      ),
                    ],
                  ),
                ),
                if (hasUnread) ...[
                  const SizedBox(width: 8),
                  Container(
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
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
