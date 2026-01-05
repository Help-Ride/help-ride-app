import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:help_ride/features/rides/models/ride.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/ride_details_controller.dart';

class RideDetailsView extends GetView<RideDetailsController> {
  const RideDetailsView({super.key});

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

          return _Body(ride: ride);
        }),
      ),
      bottomNavigationBar: Obx(() {
        final ride = controller.ride.value;
        if (ride == null) return const SizedBox.shrink();

        final total = controller.totalPrice;

        return Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE9EEF6))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${ride.pricePerSeat.toStringAsFixed(0)} × ${controller.selectedSeats.value} seat',
                      style: const TextStyle(
                        color: AppColors.lightMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: ride.seatsAvailable <= 0
                      ? null
                      : controller.openConfirmSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.passengerPrimary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE9EEF6),
                    disabledForegroundColor: const Color(0xFF9AA3B2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  child: const Text(
                    'Request Ride',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _Body extends GetView<RideDetailsController> {
  const _Body({required this.ride});
  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final driverName = ride.driver?.name ?? 'Driver';

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      children: [
        _Card(
          child: Row(
            children: [
              _Avatar(initials: _initials(driverName)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            driverName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _Pill(text: 'Verified'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '⭐ 4.9  •  127 rides  •  Since 2023',
                      style: TextStyle(
                        color: AppColors.lightMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                Get.snackbar('Call', 'Call feature later'),
                            icon: const Icon(Icons.call, size: 18),
                            label: const Text('Call'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Get.snackbar(
                              'Message',
                              'Message feature later',
                            ),
                            icon: const Icon(
                              Icons.chat_bubble_outline,
                              size: 18,
                            ),
                            label: const Text('Message'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        _SectionTitle('Trip Details'),
        _Card(
          child: Column(
            children: [
              _TripRow(
                icon: Icons.my_location,
                title: 'Pickup',
                value: ride.fromCity,
              ),
              const SizedBox(height: 10),
              _TripRow(
                icon: Icons.place,
                title: 'Destination',
                value: ride.toCity,
                iconColor: AppColors.passengerPrimary,
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFE9EEF6)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MiniInfo(
                      label: 'Date & Time',
                      value: _formatDateTime(ride.startTime),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: _MiniInfo(
                      label: 'Duration',
                      value: '45 min (placeholder)',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        _SectionTitle('Select Seats'),
        _Card(
          child: Obx(() {
            final max = ride.seatsAvailable <= 0 ? 1 : ride.seatsAvailable;
            final selected = controller.selectedSeats.value.clamp(1, max);
            final options = List<int>.generate(max, (i) => i + 1);

            return Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 10,
                    children: options.map((n) {
                      final active = n == selected;
                      return _SeatChip(
                        text: '$n seat${n == 1 ? '' : 's'}',
                        active: active,
                        onTap: () => controller.setSeats(n),
                      );
                    }).toList(),
                  ),
                ),
                Text(
                  '${ride.seatsAvailable} available',
                  style: const TextStyle(
                    color: AppColors.lightMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            );
          }),
        ),

        const SizedBox(height: 14),

        _SectionTitle('Amenities'),
        _Card(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [_Tag('AC'), _Tag('Music'), _Tag('Pet-friendly')],
          ),
        ),

        const SizedBox(height: 14),

        _SectionTitle('Pickup Instructions'),
        _Card(
          child: const Text(
            'Will wait near the main entrance',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
      ),
    );
  }
}

class _TripRow extends StatelessWidget {
  const _TripRow({
    required this.icon,
    required this.title,
    required this.value,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor ?? AppColors.lightMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.lightMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.lightMuted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
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
        style: const TextStyle(fontWeight: FontWeight.w900),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE6EAF2)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
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

String _formatDateTime(DateTime dateTime) {
  return '${dateTime.day} ${_getMonthName(dateTime.month)}, ${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}

String _getMonthName(int month) {
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
  return months[month - 1];
}
