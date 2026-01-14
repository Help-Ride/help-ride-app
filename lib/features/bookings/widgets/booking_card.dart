import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/booking.dart';
import '../utils/booking_formatters.dart';

class BookingCard extends StatelessWidget {
  const BookingCard({super.key, required this.b});
  final Booking b;

  @override
  Widget build(BuildContext context) {
    final status = b.status.toLowerCase();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EAF2)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 10),
            color: Color(0x0A000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusPill(status: status),
              const Spacer(),
              Text(
                '\$${b.totalPrice.toStringAsFixed(0)}',
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
                  '${b.ride.fromCity}  →  ${b.ride.toCity}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
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
                Icons.calendar_today_outlined,
                size: 16,
                color: AppColors.lightMuted,
              ),
              const SizedBox(width: 6),
              Text(
                formatDateTime(b.ride.startTime),
                style: const TextStyle(color: AppColors.lightMuted),
              ),
              const SizedBox(width: 14),
              const Icon(
                Icons.person_outline,
                size: 18,
                color: AppColors.lightMuted,
              ),
              const SizedBox(width: 6),
              Text(
                shortId(b.ride.driverId),
                style: const TextStyle(color: AppColors.lightMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});
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
    if (s.contains('confirmed'))
      return (const Color(0xFFE7F8EF), const Color(0xFF179C5E), 'Confirmed');
    if (s.contains('pending'))
      return (const Color(0xFFFFF2D6), const Color(0xFFB86B00), 'Pending');
    if (s.contains('cancel'))
      return (const Color(0xFFFFE2E2), const Color(0xFFD64545), 'Cancelled');
    if (s.contains('completed'))
      return (const Color(0xFFEFF2F6), const Color(0xFF6B7280), 'Completed');
    return (const Color(0xFFEFF2F6), const Color(0xFF6B7280), s);
  }
}
