import 'package:flutter/material.dart';
import '../../bookings/utils/booking_formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../models/ride_request.dart';

class RideRequestCard extends StatelessWidget {
  const RideRequestCard({
    super.key,
    required this.request,
    required this.onEdit,
    required this.onCancel,
    required this.canceling,
  });

  final RideRequest request;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final bool canceling;

  bool get _isCanceled {
    final s = request.status.toLowerCase();
    return s.contains('cancel') || s.contains('deleted');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final status = request.status.toLowerCase();

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
              _StatusPill(status: status),
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
                const SizedBox(width: 10),
                Icon(Icons.timer_outlined, size: 16, color: muted),
                const SizedBox(width: 6),
                Text(
                  request.arrivalTime!,
                  style: TextStyle(color: muted),
                ),
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
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.loop_outlined, size: 16, color: muted),
              const SizedBox(width: 6),
              Text(
                _prettyEnum(request.rideType),
                style: TextStyle(color: muted),
              ),
              const SizedBox(width: 12),
              Icon(Icons.swap_horiz, size: 16, color: muted),
              const SizedBox(width: 6),
              Text(
                _prettyEnum(request.tripType),
                style: TextStyle(color: muted),
              ),
            ],
          ),
          if (!_isCanceled) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: canceling ? null : onEdit,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: canceling ? null : onCancel,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: Text(canceling ? 'Cancelling...' : 'Cancel'),
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
    if (s.contains('pending'))
      return (const Color(0xFFFFF2D6), const Color(0xFFB86B00), 'Pending');
    if (s.contains('matched') || s.contains('offered'))
      return (const Color(0xFFE7F8EF), const Color(0xFF179C5E), 'Matched');
    if (s.contains('cancel'))
      return (const Color(0xFFFFE2E2), const Color(0xFFD64545), 'Cancelled');
    return (const Color(0xFFEFF2F6), const Color(0xFF6B7280), 'Open');
  }
}

String _prettyEnum(String raw) {
  return raw
      .split('-')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
