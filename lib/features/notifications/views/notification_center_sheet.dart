import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/notification_center_controller.dart';
import '../models/app_notification.dart';
import '../widgets/notification_empty_state.dart';
import '../widgets/notification_list_item.dart';

Future<void> showNotificationCenterSheet(BuildContext context) async {
  final controller = Get.find<NotificationCenterController>();
  controller.fetchNotifications(silent: true);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _NotificationCenterSheet(),
  );
}

class _NotificationCenterSheet extends GetView<NotificationCenterController> {
  const _NotificationCenterSheet();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F141D) : const Color(0xFFF7F9FC);
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return FractionallySizedBox(
      heightFactor: 0.92,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: muted.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifications',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Obx(
                            () => Text(
                              controller.unreadCount > 0
                                  ? '${controller.unreadCount} unread updates'
                                  : 'Ride, payment, and account updates',
                              style: TextStyle(
                                color: muted,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Obx(
                      () => TextButton(
                        onPressed:
                            controller.unreadCount == 0 ||
                                controller.markAllLoading.value
                            ? null
                            : () => controller.markAllRead(),
                        child: Text(
                          controller.markAllLoading.value
                              ? 'Working...'
                              : 'Mark all read',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Obx(() {
                    if (controller.loading.value &&
                        controller.notifications.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (controller.error.value != null &&
                        controller.notifications.isEmpty) {
                      return NotificationEmptyState(
                        title: 'Unable to load notifications',
                        subtitle: controller.error.value!,
                        onRefresh: () => controller.fetchNotifications(),
                      );
                    }

                    if (controller.notifications.isEmpty) {
                      return NotificationEmptyState(
                        title: 'You\'re all caught up',
                        subtitle:
                            'High-priority ride updates will still surface on the home screen when needed.',
                        onRefresh: () => controller.fetchNotifications(),
                      );
                    }

                    final sections = controller.sections;
                    return RefreshIndicator(
                      onRefresh: () => controller.fetchNotifications(),
                      child: ListView.separated(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).padding.bottom + 28,
                        ),
                        itemCount: sections.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final section = sections[index];
                          return _NotificationSection(
                            section: section,
                            onTap: controller.openNotification,
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
      ),
    );
  }
}

class _NotificationSection extends StatelessWidget {
  const _NotificationSection({required this.section, required this.onTap});

  final NotificationSection section;
  final ValueChanged<AppNotificationItem> onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            section.title,
            style: TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
            ),
          ),
        ),
        ...section.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: NotificationListItem(
              notification: item,
              onTap: () => onTap(item),
            ),
          ),
        ),
      ],
    );
  }
}
