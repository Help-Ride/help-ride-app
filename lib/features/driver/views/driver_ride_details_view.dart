import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:help_ride/features/driver/controllers/driver_ride_details_controller.dart';
import 'package:help_ride/features/driver/widgets/my_rides/ride_formatters.dart';
import 'package:help_ride/features/rides/models/ride.dart';
import 'package:help_ride/features/rides/widgets/ride_details/ride_trip_details_card.dart';
import 'package:help_ride/features/rides/widgets/ride_details/ride_ui.dart';
import '../../../core/theme/app_colors.dart';

class DriverRideDetailsView extends GetView<DriverRideDetailsController> {
  const DriverRideDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.lightBg,
        elevation: 0,
        foregroundColor: AppColors.lightText,
        title: const Text(
          'Ride Details',
          style: TextStyle(fontWeight: FontWeight.w900),
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

              const SectionTitle('Seats'),
              _DriverSeatsCard(ride: ride),
              const SizedBox(height: 14),

              const SectionTitle('Timing'),
              _DriverTimingCard(ride: ride),
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
    final booked = (ride.seatsTotal - ride.seatsAvailable).clamp(0, ride.seatsTotal);

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
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.place_outlined,
                size: 18,
                color: AppColors.lightMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${ride.fromCity}  →  ${ride.toCity}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppColors.lightMuted,
              ),
              const SizedBox(width: 6),
              Text(
                fmtDateTime(ride.startTime),
                style: const TextStyle(color: AppColors.lightMuted),
              ),
              const SizedBox(width: 14),
              const Icon(
                Icons.people_outline,
                size: 18,
                color: AppColors.lightMuted,
              ),
              const SizedBox(width: 6),
              Text(
                '$booked/${ride.seatsTotal} booked',
                style: const TextStyle(color: AppColors.lightMuted),
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
    final booked = (ride.seatsTotal - ride.seatsAvailable).clamp(0, ride.seatsTotal);
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: MiniInfo(
              label: 'Total seats',
              value: '${ride.seatsTotal}',
            ),
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
            child: MiniInfo(
              label: 'Booked',
              value: '$booked',
            ),
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
