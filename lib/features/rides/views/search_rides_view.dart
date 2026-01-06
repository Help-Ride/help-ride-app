import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/search_rides_controller.dart';
import '../widgets/route_subtitle.dart';
import '../widgets/ride_card.dart';

class SearchRidesView extends GetView<SearchRidesController> {
  const SearchRidesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.lightBg,
        elevation: 0,
        foregroundColor: AppColors.lightText,
        title: const Text(
          'Available Rides',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(() {
                final from = controller.fromCity.value;
                final to = controller.toCity.value;
                if (from.isEmpty || to.isEmpty) return const SizedBox.shrink();
                return RouteSubtitle(fromCity: from, toCity: to);
              }),
              const SizedBox(height: 10),

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
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.error),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: controller.fetch,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final rides = controller.rides;
                if (rides.isEmpty) {
                  return const Expanded(
                    child: Center(
                      child: Text(
                        'No rides found.',
                        style: TextStyle(color: AppColors.lightMuted),
                      ),
                    ),
                  );
                }

                return Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 18),
                    itemCount: rides.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, i) => RideCard(ride: rides[i]),
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
