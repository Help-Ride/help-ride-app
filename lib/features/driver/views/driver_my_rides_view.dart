import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/driver_my_rides_controller.dart';
import '../widgets/my_rides/rides_tabs.dart';
import '../widgets/my_rides/driver_ride_card.dart';

class DriverMyRidesView extends GetView<DriverMyRidesController> {
  const DriverMyRidesView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: isDark ? AppColors.darkText : AppColors.lightText,
        title: const Text(
          'My Rides',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          child: Column(
            children: [
              Obx(
                () => DriverRidesTabs(
                  active: controller.tab.value,
                  onChange: controller.setTab,
                ),
              ),
              const SizedBox(height: 14),

              Obx(() {
                if (controller.loading.value) {
                  return const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final err = controller.error.value;
                if (err != null) {
                  return Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            err,
                            style: const TextStyle(color: AppColors.error),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: controller.refreshAll,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final list = controller.filtered;
                if (list.isEmpty) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        'No rides yet. Use “Create a Ride” from Home.',
                        style: TextStyle(color: muted),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return Expanded(
                  child: RefreshIndicator(
                    onRefresh: controller.refreshAll,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 18),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (_, i) => DriverRideCard(ride: list[i]),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
