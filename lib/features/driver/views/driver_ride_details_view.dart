import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:help_ride/features/driver/controllers/driver_ride_details_controller.dart';
import 'package:help_ride/features/driver/widgets/my_rides/ride_formatters.dart';
import 'package:help_ride/features/driver/widgets/requests/driver_request_card.dart';
import 'package:help_ride/features/driver/widgets/requests/driver_ride_requests_tabs.dart';
import 'package:help_ride/features/rides/models/ride.dart';
import 'package:help_ride/features/rides/widgets/ride_details/ride_trip_details_card.dart';
import 'package:help_ride/features/rides/widgets/ride_details/ride_info_card.dart';
import 'package:help_ride/features/rides/widgets/ride_details/ride_ui.dart';
import '../../../core/theme/app_colors.dart';

class DriverRideDetailsView extends GetView<DriverRideDetailsController> {
  const DriverRideDetailsView({super.key});

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
          'Ride Details',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.loading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final err = controller.error.value;
          if (err != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(18),
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

          final ride = controller.ride.value;
          if (ride == null) {
            return const Center(child: Text('Ride not found.'));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            children: [
              _DriverRideSummaryCard(ride: ride),
              const SizedBox(height: 14),

              const SectionTitle('Trip Details'),
              RideTripDetailsCard(ride: ride),
              const SizedBox(height: 14),

              const SectionTitle('Ride Info'),
              RideInfoCard(ride: ride),
              const SizedBox(height: 14),

              const SectionTitle('Seats'),
              _DriverSeatsCard(ride: ride),
              const SizedBox(height: 14),

              const SectionTitle('Timing'),
              _DriverTimingCard(ride: ride),
              const SizedBox(height: 18),

              const SectionTitle('Ride Actions'),
              Obx(
                () => _DriverRideActionsCard(
                  canStart: controller.canStartRide,
                  canComplete: controller.canCompleteRide,
                  loading: controller.rideActionLoading.value,
                  error: controller.rideActionError.value,
                  unpaidBookingIds: controller.unpaidBlockingBookingIds.toList(
                    growable: false,
                  ),
                  onStart: controller.startRide,
                  onComplete: controller.completeRide,
                  isDark: isDark,
                ),
              ),
              const SizedBox(height: 18),

              const SectionTitle('Booking Requests'),
              Obx(() {
                final count = controller.newCount;
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    count == 1 ? '1 new request' : '$count new requests',
                    style: TextStyle(color: muted),
                  ),
                );
              }),
              const SizedBox(height: 12),
              Obx(
                () => DriverRideRequestsTabs(
                  active: controller.requestsTab.value,
                  onChange: controller.setRequestsTab,
                  newCount: controller.newCount,
                  offeredCount: controller.offeredCount,
                ),
              ),
              const SizedBox(height: 14),
              Obx(() {
                if (controller.requestsLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                final err = controller.requestsError.value;
                if (err != null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          err,
                          style: const TextStyle(color: AppColors.error),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: controller.fetchRequests,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final list = controller.filteredRequests;
                if (list.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        'No booking requests yet.',
                        style: TextStyle(color: muted),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    for (int i = 0; i < list.length; i++) ...[
                      DriverRequestCard(
                        booking: list[i],
                        busy: controller.isActing(list[i].id),
                        onConfirm: () => controller.confirmBooking(list[i].id),
                        onReject: () => controller.rejectBooking(list[i].id),
                      ),
                      if (i != list.length - 1) const SizedBox(height: 14),
                    ],
                  ],
                );
              }),
            ],
          );
        }),
      ),
    );
  }
}

class _DriverRideSummaryCard extends StatelessWidget {
  const _DriverRideSummaryCard({required this.ride});
  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final status = ride.status.toLowerCase();
    final booked = (ride.seatsTotal - ride.seatsAvailable).clamp(
      0,
      ride.seatsTotal,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusPill(status: status),
              const Spacer(),
              Text(
                '\$${ride.pricePerSeat.toStringAsFixed(0)}/seat',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.place_outlined, size: 18, color: muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${compactAddress(ride.fromCity)}  →  ${compactAddress(ride.toCity, maxParts: 4)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 16, color: muted),
              const SizedBox(width: 6),
              Text(fmtDateTime(ride.startTime), style: TextStyle(color: muted)),
              const SizedBox(width: 14),
              Icon(Icons.people_outline, size: 18, color: muted),
              const SizedBox(width: 6),
              Text(
                '$booked/${ride.seatsTotal} booked',
                style: TextStyle(color: muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DriverSeatsCard extends StatelessWidget {
  const _DriverSeatsCard({required this.ride});
  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final booked = (ride.seatsTotal - ride.seatsAvailable).clamp(
      0,
      ride.seatsTotal,
    );
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: MiniInfo(label: 'Total seats', value: '${ride.seatsTotal}'),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: MiniInfo(
              label: 'Available',
              value: '${ride.seatsAvailable}',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: MiniInfo(label: 'Booked', value: '$booked'),
          ),
        ],
      ),
    );
  }
}

class _DriverTimingCard extends StatelessWidget {
  const _DriverTimingCard({required this.ride});
  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final arrival = ride.arrivalTime;
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: MiniInfo(
              label: 'Start time',
              value: fmtDateTime(ride.startTime),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: MiniInfo(
              label: 'Arrival',
              value: arrival == null ? 'Not set' : fmtDateTime(arrival),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverRideActionsCard extends StatelessWidget {
  const _DriverRideActionsCard({
    required this.canStart,
    required this.canComplete,
    required this.loading,
    required this.error,
    required this.unpaidBookingIds,
    required this.onStart,
    required this.onComplete,
    required this.isDark,
  });

  final bool canStart;
  final bool canComplete;
  final bool loading;
  final String? error;
  final List<String> unpaidBookingIds;
  final VoidCallback onStart;
  final VoidCallback onComplete;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: loading || !canStart ? null : onStart,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.passengerPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: loading && canStart
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Start ride'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: loading || !canComplete ? null : onComplete,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: loading && canComplete
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Complete ride'),
                ),
              ),
            ],
          ),
          if (error != null && error!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              error!,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (unpaidBookingIds.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Unpaid bookings: ${unpaidBookingIds.join(', ')}',
              style: TextStyle(
                color: muted,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String text;

    if (status.contains('open')) {
      bg = const Color(0xFFEFF6FF);
      fg = const Color(0xFF2F6BFF);
      text = 'Open';
    } else if (status.contains('ongoing')) {
      bg = const Color(0xFFFFF2D6);
      fg = const Color(0xFFB86B00);
      text = 'Ongoing';
    } else if (status.contains('completed')) {
      bg = const Color(0xFFEFF2F6);
      fg = const Color(0xFF6B7280);
      text = 'Completed';
    } else if (status.contains('cancel')) {
      bg = const Color(0xFFFFE2E2);
      fg = const Color(0xFFD64545);
      text = 'Cancelled';
    } else {
      bg = const Color(0xFFEFF2F6);
      fg = const Color(0xFF6B7280);
      text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}
