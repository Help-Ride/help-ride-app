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
    final driver = ride.driver;
    final driverName = ride.driver?.name ?? 'Driver';
    final rating = driver?.rating;
    final totalRides = driver?.ridesCount;
    final duration = _rideDurationLabel(ride);
    final pickup = _compactLocation(ride.fromCity);
    final dropoff = _compactLocation(ride.toCity);
    final pickupInstructions = _cleanText(ride.pickupInstructions);
    final notes = _cleanText(ride.notes);
    final stops = ride.stops
        .map((stop) => _compactLocation(stop))
        .where((stop) => stop.isNotEmpty)
        .toList();
    final amenities = ride.amenities
        .map(_amenityLabel)
        .where((item) => item.isNotEmpty)
        .toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final isPast = !ride.startTime.isAfter(DateTime.now());
    final isSoldOut = ride.seatsAvailable <= 0;
    final bookDisabled = isPast || isSoldOut;
    final cardTint = isDark ? const Color(0xFF1C2331) : const Color(0xFFF7FAFD);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Avatar(initials: initials(driverName)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Text(
                            driverName,
                            maxLines: 2,
                            overflow: TextOverflow.fade,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        if (driver?.isVerified == true) ...[
                          const SizedBox(width: 8),
                          const Pill(text: 'Verified'),
                        ],
                        if (ride.isRecurring) ...[
                          const SizedBox(width: 8),
                          const Pill(text: 'Recurring'),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _driverMetaText(
                        rating: rating,
                        totalRides: totalRides,
                        sinceYear: driver?.sinceYear,
                      ),
                      style: TextStyle(
                        color: muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${ride.pricePerSeat.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    'per seat',
                    style: TextStyle(
                      color: muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardTint,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF232836) : const Color(0xFFE9EEF6),
              ),
            ),
            child: Column(
              children: [
                _RoutePointRow(
                  icon: Icons.radio_button_checked,
                  iconColor: AppColors.passengerPrimary,
                  title: pickup,
                  trailing: formatDateTime(ride.startTime),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 9),
                  child: Container(
                    width: 2,
                    height: 18,
                    color: isDark
                        ? const Color(0xFF2B3344)
                        : const Color(0xFFDCE4F0),
                  ),
                ),
                _RoutePointRow(
                  icon: Icons.location_on,
                  iconColor: AppColors.driverPrimary,
                  title: dropoff,
                  trailing: ride.arrivalTime != null
                      ? 'Arrives ${_formatTime(ride.arrivalTime!)}'
                      : (duration ?? 'Arrival time not listed'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.event_seat_outlined,
                label: _seatSummaryText(
                  seatsAvailable: ride.seatsAvailable,
                  seatsTotal: ride.seatsTotal,
                ),
              ),
              _InfoChip(
                icon: Icons.schedule,
                label: duration ?? 'Time estimate unavailable',
              ),
              _InfoChip(
                icon: ride.isRecurring ? Icons.repeat : Icons.route,
                label: ride.isRecurring
                    ? 'Repeats ${ride.recurrenceLabel}'
                    : (stops.isEmpty
                          ? 'Direct ride'
                          : '${stops.length} stop${stops.length == 1 ? '' : 's'}'),
              ),
              ...amenities.take(2).map(
                (item) => _InfoChip(icon: Icons.check_circle_outline, label: item),
              ),
              if (amenities.length > 2)
                _InfoChip(
                  icon: Icons.add_circle_outline,
                  label: '+${amenities.length - 2} more',
                ),
            ],
          ),

          if (pickupInstructions != null || notes != null || stops.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF151B25) : const Color(0xFFF9FBFE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF232836)
                      : const Color(0xFFE9EEF6),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (pickupInstructions != null)
                    _InlineInfoRow(
                      icon: Icons.directions_walk_outlined,
                      label: 'Pickup',
                      value: pickupInstructions,
                    ),
                  if (pickupInstructions != null &&
                      (notes != null || stops.isNotEmpty))
                    const SizedBox(height: 10),
                  if (stops.isNotEmpty)
                    _InlineInfoRow(
                      icon: Icons.add_road_outlined,
                      label: 'Stops',
                      value: stops.take(2).join(' • '),
                    ),
                  if (stops.isNotEmpty && notes != null)
                    const SizedBox(height: 10),
                  if (notes != null)
                    _InlineInfoRow(
                      icon: Icons.info_outline,
                      label: 'Ride note',
                      value: notes,
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          Row(
            children: [
              Text(
                'Select seats',
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                isSoldOut ? 'Sold out' : _seatSelectorHint(ride.seatsAvailable),
                style: TextStyle(
                  color: isSoldOut ? AppColors.error : muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          if (isSoldOut)
            Text(
              'This ride no longer has open seats.',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Obx(() {
              final max = ride.seatsAvailable;
              final selected = controller.getSelectedSeats(ride.id, max);
              final options = List<int>.generate(max, (i) => i + 1);

              return Wrap(
                spacing: 10,
                runSpacing: 10,
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
                        '\$${ride.pricePerSeat.toStringAsFixed(0)} x $selected ${selected == 1 ? 'seat' : 'seats'}',
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
                    final max = ride.seatsAvailable <= 0 ? 1 : ride.seatsAvailable;
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
                  onPressed: bookDisabled
                      ? null
                      : () {
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

  String _driverMetaText({
    required double? rating,
    required int? totalRides,
    required int? sinceYear,
  }) {
    final parts = <String>[];
    if (rating != null) {
      parts.add('⭐ ${rating.toStringAsFixed(1)}');
    }
    if (totalRides != null && totalRides > 0) {
      parts.add('$totalRides rides');
    }
    if (sinceYear != null && sinceYear > 0) {
      parts.add('Since $sinceYear');
    }
    if (parts.isEmpty) {
      return 'New driver';
    }
    return parts.join('  •  ');
  }

  String? _rideDurationLabel(Ride ride) {
    final arrivalTime = ride.arrivalTime;
    if (arrivalTime == null) return null;
    final duration = arrivalTime.difference(ride.startTime);
    if (duration.inMinutes <= 0) return null;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours <= 0) return '${duration.inMinutes} min trip';
    if (minutes == 0) return '$hours hr trip';
    return '$hours hr $minutes min trip';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  String _compactLocation(String location) {
    final raw = location.trim();
    if (raw.isEmpty) return 'Location not provided';
    final parts = raw
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return raw;
    if (parts.length <= 2) return parts.join(', ');
    return parts.take(2).join(', ');
  }

  String? _cleanText(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    return text.replaceAll(RegExp(r'\s+'), ' ');
  }

  String _seatSummaryText({
    required int seatsAvailable,
    required int seatsTotal,
  }) {
    if (seatsAvailable <= 0) return 'Sold out';
    if (seatsTotal <= 0) {
      return '$seatsAvailable seat${seatsAvailable == 1 ? '' : 's'} left';
    }
    return '$seatsAvailable of $seatsTotal seats left';
  }

  String _seatSelectorHint(int seatsAvailable) {
    if (seatsAvailable <= 0) return 'No seats left';
    if (seatsAvailable == 1) return '1 seat left';
    return '$seatsAvailable seats left';
  }

  String _amenityLabel(String value) {
    final token = value.trim().toLowerCase();
    if (token.isEmpty) return '';
    switch (token) {
      case 'ac':
        return 'AC';
      case 'wifi':
        return 'WiFi';
      case 'pet_friendly':
      case 'pet-friendly':
        return 'Pet-friendly';
      case 'luggage_space':
      case 'luggage-space':
        return 'Luggage';
      case 'child_seat':
      case 'child-seat':
        return 'Child seat';
      default:
        final words = token
            .replaceAll(RegExp(r'[_-]+'), ' ')
            .split(' ')
            .where((word) => word.trim().isNotEmpty)
            .toList();
        return words
            .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
            .join(' ');
    }
  }
}

class _RoutePointRow extends StatelessWidget {
  const _RoutePointRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          trailing,
          style: TextStyle(
            color: muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151B25) : const Color(0xFFF7FAFD),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark ? const Color(0xFF232836) : const Color(0xFFE5EBF4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: muted),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineInfoRow extends StatelessWidget {
  const _InlineInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 17, color: muted),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
