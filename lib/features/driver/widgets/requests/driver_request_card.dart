import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:help_ride/features/bookings/models/booking.dart';
import 'package:help_ride/features/bookings/utils/booking_formatters.dart';
import '../../../../core/theme/app_colors.dart';
import 'request_formatters.dart';

class DriverRequestCard extends StatelessWidget {
  const DriverRequestCard({
    super.key,
    required this.booking,
    required this.onConfirm,
    required this.onReject,
    required this.busy,
  });

  final Booking booking;
  final VoidCallback onConfirm;
  final VoidCallback onReject;
  final bool busy;

  bool get _isOffered {
    final s = booking.status.toLowerCase();
    return s.contains('confirm') ||
        s.contains('accepted') ||
        s.contains('offer');
  }

  bool get _isRejected {
    final s = booking.status.toLowerCase();
    return s.contains('reject') || s.contains('cancel');
  }

  @override
  Widget build(BuildContext context) {
    final passenger = booking.passenger;
    final name = passenger?.name ?? 'Passenger';
    final created = booking.updatedAt ?? booking.createdAt;
    final note = (booking.note ?? '').trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9E6FF)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 16,
            offset: Offset(0, 8),
            color: Color(0x10000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusPill(status: booking.status),
              const Spacer(),
              Text(
                timeAgo(created),
                style: const TextStyle(color: AppColors.lightMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Avatar(initials: initials(name)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _RatingTrips(passenger: passenger),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE9EEF6)),
          const SizedBox(height: 12),
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
                  '${booking.ride.fromCity}  →  ${booking.ride.toCity}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
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
              Expanded(
                child: Text(
                  formatDateTime(booking.ride.startTime),
                  style: const TextStyle(color: AppColors.lightMuted),
                ),
              ),
              const Icon(
                Icons.person_outline,
                size: 18,
                color: AppColors.lightMuted,
              ),
              const SizedBox(width: 6),
              Text(
                '${booking.seatsBooked} seat${booking.seatsBooked == 1 ? '' : 's'}',
                style: const TextStyle(color: AppColors.lightMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.attach_money,
                size: 18,
                color: AppColors.lightMuted,
              ),
              const SizedBox(width: 6),
              Text(
                'Max \$${booking.ride.pricePerSeat.toStringAsFixed(0)}/seat',
                style: const TextStyle(color: AppColors.lightMuted),
              ),
            ],
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F5F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                note,
                style: const TextStyle(color: AppColors.lightText),
              ),
            ),
          ],
          if (!_isRejected) ...[
            const SizedBox(height: 14),
            _isOffered
                ? OutlinedButton.icon(
                    onPressed: busy
                        ? null
                        : () => Get.snackbar(
                              'Message',
                              'Message passenger coming soon.',
                            ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Message Passenger'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: busy ? null : onReject,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: busy ? null : onConfirm,
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: const Text('Send Offer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.driverPrimary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
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
    final (bg, fg, text) = _style(status);
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

  (Color, Color, String) _style(String s) {
    final status = s.toLowerCase();
    if (status.contains('pending') ||
        status.contains('new') ||
        status.contains('request')) {
      return (
        const Color(0xFFE8F0FF),
        const Color(0xFF2F6BFF),
        'New Request'
      );
    }
    if (status.contains('confirm') || status.contains('offer')) {
      return (
        const Color(0xFFE7F8EF),
        const Color(0xFF179C5E),
        'Offer Sent'
      );
    }
    if (status.contains('reject') || status.contains('cancel')) {
      return (
        const Color(0xFFFFE2E2),
        const Color(0xFFD64545),
        'Declined'
      );
    }
    return (const Color(0xFFEFF2F6), const Color(0xFF6B7280), s);
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

class _RatingTrips extends StatelessWidget {
  const _RatingTrips({required this.passenger});
  final BookingPassenger? passenger;

  @override
  Widget build(BuildContext context) {
    final rating = passenger?.rating;
    final trips = passenger?.trips;
    if (rating == null && trips == null) {
      return const Text(
        '⭐ 4.8 • 45 trips',
        style: TextStyle(
          color: AppColors.lightMuted,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final ratingText = rating == null ? '—' : rating.toStringAsFixed(1);
    final tripsText = trips == null ? 'trips' : '$trips trips';

    return Text(
      '⭐ $ratingText • $tripsText',
      style: const TextStyle(
        color: AppColors.lightMuted,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
