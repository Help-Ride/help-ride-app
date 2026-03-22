import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:help_ride/features/rides/controllers/ride_details_controller.dart';
import 'package:help_ride/features/rides/models/ride.dart';
import 'package:help_ride/features/rides/widgets/ride_formatters.dart';
import 'package:help_ride/features/rides/widgets/ride_details/ride_ui.dart';
import '../../../../../core/theme/app_colors.dart';

class RideDriverCard extends GetView<RideDetailsController> {
  const RideDriverCard({super.key, required this.ride});
  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final driverName = ride.driver?.name ?? 'Driver';
    final driver = ride.driver;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarUrl = driver?.avatarUrl ?? '';
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                      color: muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 10),
                if (controller.canOpenBookingChat)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: controller.openBookingChat,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.passengerPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text(
                        'Chat',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF151B25)
                          : const Color(0xFFF7FAFD),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF232836)
                            : const Color(0xFFE6EAF2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lock_outline, size: 16, color: muted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            controller.bookingInfoMessage,
                            style: TextStyle(
                              color: muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
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
