import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:help_ride/features/rides/models/ride.dart';
import 'package:help_ride/features/rides/widgets/ride_formatters.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/search_rides_controller.dart';
import 'ride_ui.dart';

class RideCard extends GetView<SearchRidesController> {
  const RideCard({super.key, required this.ride});
  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final driverName = ride.driver?.name ?? 'Driver';
    final rating = 4.8; // placeholder
    final totalRides = 93; // placeholder
    final durationMin = 50; // placeholder
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Avatar(initials: initials(driverName)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        // driver name row handled below with Flexible
                      ],
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            driverName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Pill(text: 'Verified'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 16,
                          color: Color(0xFFF4B400),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('•', style: TextStyle(color: muted)),
                        const SizedBox(width: 8),
                        Text(
                          '$totalRides rides',
                          style: TextStyle(color: muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 18, color: muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  formatDateTime(ride.startTime),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
              Icon(Icons.schedule, size: 18, color: muted),
              const SizedBox(width: 6),
              Text(
                '$durationMin min',
                style: TextStyle(
                  color: muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Icon(Icons.event_seat_outlined, size: 18, color: muted),
              const SizedBox(width: 8),
              Text(
                '${ride.seatsAvailable} seats available',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Select seats:',
              style: TextStyle(
                color: muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Obx(() {
            final max = ride.seatsAvailable <= 0 ? 1 : ride.seatsAvailable;
            final selected = controller.getSelectedSeats(ride.id, max);
            final options = List<int>.generate(max, (i) => i + 1);

            return Wrap(
              spacing: 10,
              children: options.map((n) {
                final isActive = n == selected;
                return SeatChip(
                  text: '$n',
                  active: isActive,
                  onTap: () => controller.setSelectedSeats(ride.id, n),
                );
              }).toList(),
            );
          }),

          const SizedBox(height: 14),
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF232836) : const Color(0xFFE9EEF6),
          ),
          const SizedBox(height: 14),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Obx(() {
                  final max = ride.seatsAvailable <= 0
                      ? 1
                      : ride.seatsAvailable;
                  final selected = controller.getSelectedSeats(ride.id, max);
                  final total = ride.pricePerSeat * selected;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\$${total.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$${ride.pricePerSeat.toStringAsFixed(0)} × $selected seat',
                        style: TextStyle(
                          color: muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  );
                }),
              ),

              SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: () {
                    final max = ride.seatsAvailable <= 0
                        ? 1
                        : ride.seatsAvailable;
                    final seats = controller.getSelectedSeats(ride.id, max);

                    Get.toNamed(
                      '/rides/${ride.id}',
                      arguments: {'seats': seats},
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: isDark ? const Color(0xFF232836) : const Color(0xFFE2E6EF),
                    ),
                  ),
                  child: const Text('Details'),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    final max = ride.seatsAvailable <= 0
                        ? 1
                        : ride.seatsAvailable;
                    final seats = controller.getSelectedSeats(ride.id, max);

                    Get.snackbar(
                      'Book',
                      'Booking $seats seat(s) for ride ${ride.id}',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.passengerPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Book'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
