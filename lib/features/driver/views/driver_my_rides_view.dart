import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/driver_my_rides_controller.dart';
import '../models/driver_ride_management.dart';
import '../routes/driver_routes.dart';
import '../widgets/my_rides/driver_recurring_series_card.dart';
import '../widgets/my_rides/driver_ride_bookings_sheet.dart';
import '../widgets/my_rides/driver_ride_card.dart';
import '../widgets/my_rides/ride_list_filters.dart';
import '../widgets/my_rides/ride_scope_sheet.dart';
import '../widgets/my_rides/rides_tabs.dart';

class DriverMyRidesView extends GetView<DriverMyRidesController> {
  const DriverMyRidesView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: textPrimary,
        title: const Text(
          'My Rides',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(
                () => DriverRidesTabs(
                  active: controller.tab.value,
                  onChange: controller.setTab,
                ),
              ),
              const SizedBox(height: 12),
              Obx(
                () => DriverRideListFilters(
                  active: controller.listFilter.value,
                  onChange: controller.setListFilter,
                ),
              ),
              const SizedBox(height: 12),
              Obx(() {
                if (controller.loading.value) {
                  return const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final err = controller.error.value;
                if (err != null) {
                  return Expanded(
                    child: RefreshIndicator(
                      onRefresh: controller.refreshAll,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 140),
                          Center(
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
                        ],
                      ),
                    ),
                  );
                }

                final entries = controller.filteredEntries;
                if (entries.isEmpty) {
                  return Expanded(
                    child: RefreshIndicator(
                      onRefresh: controller.refreshAll,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 220),
                          Center(
                            child: Text(
                              _emptyMessage(controller.listFilter.value),
                              style: TextStyle(color: muted),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
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
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (_, index) {
                        final entry = entries[index];
                        if (entry.isSeries) {
                          final series = entry.series!;
                          return DriverRecurringSeriesCard(
                            series: series,
                            onViewSeries: () => Get.toNamed(
                              DriverRoutes.rideSeries.replaceFirst(
                                ':seriesId',
                                series.id,
                              ),
                              arguments: {'seriesId': series.id},
                            ),
                            onEditSeries: () => _editSeries(context, series),
                          );
                        }

                        final ride = entry.ride!;
                        return DriverRideCard(
                          ride: ride,
                          onViewDetails: () => showDriverRideBookingsSheet(
                            context,
                            rideId: ride.id,
                            ride: ride,
                          ),
                          onEdit: () => _editOccurrence(context, ride),
                          onCancel: () => _cancelOccurrence(context, ride),
                        );
                      },
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

  String _emptyMessage(DriverRideListFilter filter) {
    switch (filter) {
      case DriverRideListFilter.all:
        return 'No rides yet. Use “Create a Ride” from Home.';
      case DriverRideListFilter.oneTime:
        return 'No one-time rides in this view.';
      case DriverRideListFilter.recurring:
        return 'No recurring series in this view.';
      case DriverRideListFilter.cancelled:
        return 'No cancelled rides or series in this view.';
      case DriverRideListFilter.occurrences:
        return 'No ride occurrences in this view.';
    }
  }

  Future<void> _editOccurrence(BuildContext context, DriverRideItem ride) async {
    if (ride.isRecurring) {
      final scope = await showRideScopeSheet(
        context: context,
        title: 'Edit recurring ride',
        subtitle:
            'Choose whether to update only this occurrence or apply changes more broadly.',
        recommendedScope: 'occurrence',
      );
      if (scope == null) return;
      await Get.toNamed(
        DriverRoutes.editRide.replaceFirst(':id', ride.id),
        arguments: {'editScope': scope},
      );
      await controller.refreshAll();
      return;
    }

    await Get.toNamed(DriverRoutes.editRide.replaceFirst(':id', ride.id));
    await controller.refreshAll();
  }

  Future<void> _editSeries(
    BuildContext context,
    DriverRideSeriesSummary series,
  ) async {
    final anchorRide = series.nextUpcomingOccurrence ?? series.anchorRide;
    final scope = await showRideScopeSheet(
      context: context,
      title: 'Edit recurring schedule',
      subtitle:
          'Choose whether to update future rides from this point or the entire series.',
      includeOccurrence: false,
      recommendedScope: 'future',
    );
    if (scope == null) return;

    await Get.toNamed(
      DriverRoutes.editRide.replaceFirst(':id', anchorRide.id),
      arguments: {'editScope': scope, 'seriesId': series.id},
    );
    await controller.refreshAll();
  }

  Future<void> _cancelOccurrence(
    BuildContext context,
    DriverRideItem ride,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String scope = 'occurrence';
    if (ride.isRecurring) {
      final selectedScope = await showRideScopeSheet(
        context: context,
        title: 'Cancel recurring ride',
        subtitle:
            'You can cancel just this occurrence or cancel future rides in this recurring series.',
        recommendedScope: 'occurrence',
      );
      if (selectedScope == null) return;
      scope = selectedScope;
    }

    final confirm = await Get.dialog<bool>(
      Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 22),
        backgroundColor: isDark ? AppColors.darkSurface : const Color(0xFFF2F2F6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cancel ride?',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
              ),
              const SizedBox(height: 12),
              Text(
                scope == 'occurrence'
                    ? 'This will cancel the selected ride occurrence for passengers.'
                    : scope == 'future'
                    ? 'This will cancel this occurrence and future rides in the series.'
                    : 'This will cancel the entire recurring series.',
                style: TextStyle(
                  color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    child: const Text('Keep'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => Get.back(result: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text('Cancel Ride'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );

    if (confirm == true) {
      await controller.cancelRide(ride.id, scope: scope);
    }
  }
}
