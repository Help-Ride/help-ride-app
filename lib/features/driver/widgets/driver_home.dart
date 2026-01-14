import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import 'mini_stat_card.dart';
import 'ride_preview_card.dart';

class DriverHomeView extends StatelessWidget {
  const DriverHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        SizedBox(
          height: 54,
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Get.toNamed('/driver/create-ride'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.driverPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text(
              "Create a Ride",
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Row(
          children: [
            Expanded(
              child: MiniStatCard(
                title: "Ride Requests",
                subtitle: "View passenger requests",
                badge: "3 New",
                accent: AppColors.driverPrimary,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: MiniStatCard(
                title: "Earnings",
                subtitle: "\$280 this week",
                accent: AppColors.driverPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const RidePreviewCard(
          from: "Downtown Toronto",
          to: "Pearson Airport",
          metaLeft: "3 available",
          metaRight: "\$25/seat",
        ),
      ],
    );
  }
}
