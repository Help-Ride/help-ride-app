import 'package:flutter/material.dart';
import '../../../ride_requests/models/ride_request.dart';
import '../../../bookings/utils/booking_formatters.dart';
import '../../../../core/theme/app_colors.dart';

class DriverRideRequestCard extends StatelessWidget {
  const DriverRideRequestCard({
    super.key,
    required this.request,
    required this.onOffer,
  });

  final RideRequest request;
  final VoidCallback onOffer;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF232836) : const Color(0xFFE6EAF2),
        ),
        boxShadow: isDark
            ? []
            : const [
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
              _StatusPill(status: request.status),
              const Spacer(),
              Text(
                formatDateTime(request.preferredDate),
                style: TextStyle(color: muted, fontSize: 12),
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
                  '${request.fromCity}  →  ${request.toCity}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: muted),
              const SizedBox(width: 6),
              Text(
                request.preferredTime,
                style: TextStyle(color: muted),
              ),
              if (request.arrivalTime != null &&
                  request.arrivalTime!.trim().isNotEmpty) ...[
                const SizedBox(width: 12),
                Icon(Icons.timer_outlined, size: 16, color: muted),
                const SizedBox(width: 6),
                Text(request.arrivalTime!, style: TextStyle(color: muted)),
              ],
              const Spacer(),
              Icon(Icons.event_seat_outlined, size: 16, color: muted),
              const SizedBox(width: 6),
              Text(
                '${request.seatsNeeded} seat${request.seatsNeeded == 1 ? '' : 's'}',
                style: TextStyle(color: muted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onOffer,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.driverPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Make Offer',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
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
    final v = s.toLowerCase();
    if (v.contains('pending') || v.contains('open')) {
      return (const Color(0xFFFFF2D6), const Color(0xFFB86B00), 'Open');
    }
    if (v.contains('matched') || v.contains('offered')) {
      return (const Color(0xFFE7F8EF), const Color(0xFF179C5E), 'Matched');
    }
    if (v.contains('cancel')) {
      return (const Color(0xFFFFE2E2), const Color(0xFFD64545), 'Cancelled');
    }
    return (const Color(0xFFEFF2F6), const Color(0xFF6B7280), s);
  }
}
