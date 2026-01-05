import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/search_rides_controller.dart';
import '../models/ride.dart';

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

                return _RouteSubtitle(fromCity: from, toCity: to);
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
                    itemBuilder: (_, i) => _RideCard(ride: rides[i]),
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

class _RouteSubtitle extends StatelessWidget {
  const _RouteSubtitle({required this.fromCity, required this.toCity});
  final String fromCity;
  final String toCity;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$fromCity  →  $toCity',
      style: const TextStyle(
        color: AppColors.lightMuted,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _RideCard extends GetView<SearchRidesController> {
  const _RideCard({required this.ride});
  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final driverName = ride.driver?.name ?? 'Driver';
    final rating = 4.8; // placeholder for now
    final totalRides = 93; // placeholder for now
    final durationMin = 50; // placeholder for now

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EAF2)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 20,
            offset: Offset(0, 10),
            color: Color(0x0A000000),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _Avatar(initials: _initials(driverName)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            driverName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _Pill(text: 'Verified'),
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
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '•',
                          style: TextStyle(color: AppColors.lightMuted),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$totalRides rides',
                          style: const TextStyle(color: AppColors.lightMuted),
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
              const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: AppColors.lightMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatDateTime(ride.startTime),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.schedule, size: 18, color: AppColors.lightMuted),
              const SizedBox(width: 6),
              Text(
                '$durationMin min',
                style: const TextStyle(
                  color: AppColors.lightMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              const Icon(
                Icons.event_seat_outlined,
                size: 18,
                color: AppColors.lightMuted,
              ),
              const SizedBox(width: 8),
              Text(
                '${ride.seatsAvailable} seats available',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Select seats:',
              style: const TextStyle(
                color: AppColors.lightMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Obx(() {
            final max = ride.seatsAvailable;
            final selected = controller.getSelectedSeats(ride.id, max);

            final options = List<int>.generate(max, (i) => i + 1);

            return Wrap(
              spacing: 10,
              children: options.map((n) {
                final isActive = n == selected;
                return _SeatChip(
                  text: '$n',
                  active: isActive,
                  onTap: () => controller.setSelectedSeats(ride.id, n),
                );
              }).toList(),
            );
          }),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE9EEF6)),
          const SizedBox(height: 14),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Obx(() {
                  final selected = controller.getSelectedSeats(
                    ride.id,
                    ride.seatsAvailable,
                  );
                  final total = ride.pricePerSeat * selected;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\$${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$${ride.pricePerSeat.toStringAsFixed(0)} × $selected seat',
                        style: const TextStyle(
                          color: AppColors.lightMuted,
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
                    final seats = controller.getSelectedSeats(
                      ride.id,
                      ride.seatsAvailable,
                    );
                    Get.toNamed(
                      '/rides/${ride.id}',
                      arguments: {'seats': seats},
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: Color(0xFFE2E6EF)),
                  ),
                  child: const Text('Details'),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    final seats = controller.getSelectedSeats(
                      ride.id,
                      ride.seatsAvailable,
                    );
                    Get.snackbar(
                      'Book',
                      'Booking $seats seat(s) for ride ${ride.id}',
                    );
                    // TODO: call booking API later
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: 44,
      decoration: const BoxDecoration(
        color: Color(0xFFE9EEF6),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          color: AppColors.lightText,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF2F6BFF),
        ),
      ),
    );
  }
}

class _SeatChip extends StatelessWidget {
  const _SeatChip({
    required this.text,
    required this.active,
    required this.onTap,
  });
  final String text;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE7F8EF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? AppColors.passengerPrimary
                : const Color(0xFFE2E6EF),
            width: 1.5,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: active ? AppColors.passengerPrimary : AppColors.lightText,
          ),
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return 'U';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
}

String _formatDateTime(DateTime dt) {
  // simple display: "Today, 2:30 PM" style is easy later; for now keep readable
  final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  final mm = dt.minute.toString().padLeft(2, '0');
  final month = _mon(dt.month);
  return '${month} ${dt.day}, $h:$mm $ampm';
}

String _mon(int m) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[(m - 1).clamp(0, 11)];
}
