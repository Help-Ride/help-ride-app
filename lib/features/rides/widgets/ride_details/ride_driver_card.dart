import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:help_ride/features/rides/models/ride.dart';
import 'package:help_ride/features/rides/widgets/ride_formatters.dart';
import 'package:help_ride/features/rides/widgets/ride_details/ride_ui.dart';
import 'package:help_ride/features/chat/services/chat_api.dart';
import 'package:help_ride/features/chat/views/chat_thread_view.dart';
import 'package:help_ride/shared/controllers/session_controller.dart';
import 'package:help_ride/shared/services/api_client.dart';
import '../../../../../core/theme/app_colors.dart';

class RideDriverCard extends StatelessWidget {
  const RideDriverCard({super.key, required this.ride});
  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final driverName = ride.driver?.name ?? 'Driver';
    final driver = ride.driver;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarUrl = driver?.avatarUrl ?? '';
    final email = (driver?.email ?? '').trim();

    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor:
                isDark ? const Color(0xFF1C2331) : const Color(0xFFE9EEF6),
            backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl.isEmpty
                ? Text(
                    initials(driverName),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  )
                : null,
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
                        driverName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (driver?.isVerified == true) const Pill(text: 'Verified'),
                  ],
                ),
                const SizedBox(height: 6),
                if (_driverMetaText(driver) != null)
                  Text(
                    _driverMetaText(driver)!,
                    style: TextStyle(
                      color:
                          isDark ? AppColors.darkMuted : AppColors.lightMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Get.snackbar('Call', 'Later'),
                        icon: const Icon(Icons.call, size: 18),
                        label: const Text('Call'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final session = Get.isRegistered<SessionController>()
                              ? Get.find<SessionController>()
                              : null;
                          final userId = session?.user.value?.id ?? '';
                          if (userId.isEmpty) {
                            Get.snackbar('Message', 'Please sign in to chat.');
                            return;
                          }

                          try {
                            final client = await ApiClient.create();
                            final api = ChatApi(client);
                            final conversation =
                                await api.createOrGetConversation(
                              rideId: ride.id,
                              passengerId: userId,
                              currentUserId: userId,
                              currentRole: session?.user.value?.roleDefault,
                            );
                            Get.to(
                              () => ChatThreadView(conversation: conversation),
                            );
                          } catch (e) {
                            Get.snackbar(
                              'Message',
                              'Unable to start chat right now.',
                            );
                          }
                        },
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text('Message'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _driverMetaText(RideDriver? driver) {
    if (driver == null) return null;
    final parts = <String>[];
    if (driver.rating != null) {
      parts.add('⭐ ${driver.rating!.toStringAsFixed(1)}');
    }
    if (driver.ridesCount != null) {
      parts.add('${driver.ridesCount} rides');
    }
    if (driver.sinceYear != null) {
      parts.add('Since ${driver.sinceYear}');
    }
    if (parts.isEmpty) return null;
    return parts.join('  •  ');
  }
}
