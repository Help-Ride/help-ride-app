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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: isDark ? AppColors.darkText : AppColors.lightText,
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
                  return Expanded(
                    child: Center(
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF1C2331) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF232836)
                                : const Color(0xFFE6EAF2),
                          ),
                          boxShadow: isDark
                              ? []
                              : const [
                                  BoxShadow(
                                    blurRadius: 18,
                                    offset: Offset(0, 10),
                                    color: Color(0x0A000000),
                                  ),
                                ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.passengerPrimary
                                    .withOpacity(isDark ? 0.25 : 0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.add_road,
                                color: AppColors.passengerPrimary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'No rides found',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: isDark
                                    ? AppColors.darkText
                                    : AppColors.lightText,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Request a ride for this route and get matched fast.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.darkMuted
                                    : AppColors.lightMuted,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () => Get.toNamed(
                                  '/ride-requests/create',
                                  arguments: {
                                    'fromCity': controller.fromCity.value,
                                    'toCity': controller.toCity.value,
                                    'seats': controller.seatsRequired.value,
                                    if (controller.fromLat.value != null)
                                      'fromLat': controller.fromLat.value,
                                    if (controller.fromLng.value != null)
                                      'fromLng': controller.fromLng.value,
                                    if (controller.toLat.value != null)
                                      'toLat': controller.toLat.value,
                                    if (controller.toLng.value != null)
                                      'toLng': controller.toLng.value,
                                  },
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.passengerPrimary,
                                  foregroundColor: Colors.white,
                                  shape: const StadiumBorder(),
                                  elevation: 0,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 18),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.add_road, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Request Ride',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
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
