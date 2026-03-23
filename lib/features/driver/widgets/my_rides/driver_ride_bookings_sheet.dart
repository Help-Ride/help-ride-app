import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../features/rides/widgets/ride_details/ride_ui.dart';
import '../../controllers/driver_my_rides_controller.dart';
import '../../controllers/driver_ride_details_controller.dart';
import '../../models/driver_ride_management.dart';
import '../requests/driver_request_card.dart';
import '../requests/driver_ride_requests_tabs.dart';
import 'ride_formatters.dart';

Future<void> showDriverRideBookingsSheet(
  BuildContext context, {
  required String rideId,
  DriverRideItem? ride,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.9,
      child: DriverRideBookingsSheet(rideId: rideId, ride: ride),
    ),
  ).whenComplete(() async {
    if (Get.isRegistered<DriverMyRidesController>()) {
      await Get.find<DriverMyRidesController>().refreshAll();
    }
  });
}

class DriverRideBookingsSheet extends StatefulWidget {
  const DriverRideBookingsSheet({super.key, required this.rideId, this.ride});

  final String rideId;
  final DriverRideItem? ride;

  @override
  State<DriverRideBookingsSheet> createState() =>
      _DriverRideBookingsSheetState();
}

class _DriverRideBookingsSheetState extends State<DriverRideBookingsSheet> {
  late final String _tag;
  late final DriverRideDetailsController _controller;

  @override
  void initState() {
    super.initState();
    _tag = 'driver-ride-bookings-${widget.rideId}';
    _controller = Get.put(
      DriverRideDetailsController(rideId: widget.rideId),
      tag: _tag,
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<DriverRideDetailsController>(tag: _tag)) {
      Get.delete<DriverRideDetailsController>(tag: _tag, force: true);
    }
    super.dispose();
  }

  Future<void> _refreshSheet() async {
    await _controller.fetch();
    await _controller.fetchRequests();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: muted.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshSheet,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
                children: [
                  Obx(() {
                    final ride = _controller.ride.value;
                    final routeText = ride == null
                        ? widget.ride == null
                              ? 'Loading ride...'
                              : '${widget.ride!.from} → ${widget.ride!.to}'
                        : '${ride.fromCity} → ${ride.toCity}';
                    final status = ride?.status ?? widget.ride?.status ?? '';
                    final startTime = ride?.startTime ?? widget.ride?.startTime;
                    final seatsTotal =
                        ride?.seatsTotal ?? widget.ride?.seatsTotal ?? 0;
                    final seatsAvailable =
                        ride?.seatsAvailable ??
                        widget.ride?.seatsAvailable ??
                        0;
                    final booked = (seatsTotal - seatsAvailable).clamp(
                      0,
                      seatsTotal,
                    );
                    final price =
                        ride?.pricePerSeat ?? widget.ride?.pricePerSeat ?? 0;
                    final startTimeLabel = startTime == null
                        ? '—'
                        : fmtDateTime(startTime);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ride Bookings',
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    routeText,
                                    style: TextStyle(
                                      color: muted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _SheetStatusPill(status: status),
                          ],
                        ),
                        const SizedBox(height: 14),
                        AppCard(
                          child: Row(
                            children: [
                              Expanded(
                                child: MiniInfo(
                                  label: 'Start time',
                                  value: startTimeLabel,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: MiniInfo(
                                  label: 'Booked',
                                  value: '$booked/$seatsTotal',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: MiniInfo(
                                  label: 'Price',
                                  value: '\$${price.toStringAsFixed(0)}/seat',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 18),
                  const SectionTitle('Ride Actions'),
                  Obx(
                    () => _RideActionsCard(
                      canStart: _controller.canStartRide,
                      canComplete: _controller.canCompleteRide,
                      loading: _controller.rideActionLoading.value,
                      error: _controller.rideActionError.value,
                      unpaidBookingIds: _controller.unpaidBlockingBookingIds
                          .toList(growable: false),
                      onStart: _controller.startRide,
                      onComplete: _controller.completeRide,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const SectionTitle('Booking Requests'),
                  Obx(() {
                    final count = _controller.newCount;
                    return Text(
                      count == 1 ? '1 new request' : '$count new requests',
                      style: TextStyle(color: muted),
                    );
                  }),
                  const SizedBox(height: 12),
                  Obx(
                    () => DriverRideRequestsTabs(
                      active: _controller.requestsTab.value,
                      onChange: _controller.setRequestsTab,
                      newCount: _controller.newCount,
                      offeredCount: _controller.offeredCount,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Obx(() {
                    if (_controller.requestsLoading.value) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final err = _controller.requestsError.value;
                    if (err != null) {
                      return AppCard(
                        child: Column(
                          children: [
                            Text(
                              err,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.error),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _controller.fetchRequests,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    final list = _controller.filteredRequests;
                    if (list.isEmpty) {
                      return AppCard(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Text(
                              'No booking requests yet.',
                              style: TextStyle(color: muted),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        for (int i = 0; i < list.length; i++) ...[
                          DriverRequestCard(
                            booking: list[i],
                            busy: _controller.isActing(list[i].id),
                            onConfirm: () =>
                                _controller.confirmBooking(list[i].id),
                            onReject: () =>
                                _controller.rejectBooking(list[i].id),
                          ),
                          if (i != list.length - 1) const SizedBox(height: 14),
                        ],
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RideActionsCard extends StatelessWidget {
  const _RideActionsCard({
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

class _SheetStatusPill extends StatelessWidget {
  const _SheetStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    Color bg;
    Color fg;
    String text;

    if (normalized.contains('open')) {
      bg = const Color(0xFFEFF6FF);
      fg = const Color(0xFF2F6BFF);
      text = 'Open';
    } else if (normalized.contains('ongoing')) {
      bg = const Color(0xFFFFF2D6);
      fg = const Color(0xFFB86B00);
      text = 'Ongoing';
    } else if (normalized.contains('completed')) {
      bg = const Color(0xFFEFF2F6);
      fg = const Color(0xFF6B7280);
      text = 'Completed';
    } else if (normalized.contains('cancel')) {
      bg = const Color(0xFFFFE2E2);
      fg = const Color(0xFFD64545);
      text = 'Cancelled';
    } else {
      bg = const Color(0xFFEFF2F6);
      fg = const Color(0xFF6B7280);
      text = status.trim().isEmpty ? 'Ride' : status;
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
