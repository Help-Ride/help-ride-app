import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/booking.dart';
import '../utils/booking_formatters.dart';

class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.b,
    this.showPay = false,
    this.isPaying = false,
    this.payButtonLabel = 'Pay now',
    this.paymentStateLabel,
    this.onPay,
    this.onDetails,
  });

  final Booking b;
  final bool showPay;
  final bool isPaying;
  final String payButtonLabel;
  final String? paymentStateLabel;
  final VoidCallback? onPay;
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) {
    final status = b.status.toLowerCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              StatusPill(status: status),
              const Spacer(),
              Text(
                '\$${b.totalPrice.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            ],
          ),
          if (paymentStateLabel != null) ...[
            const SizedBox(height: 8),
            Text(
              paymentStateLabel!,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
              ),
            ),
          ],
          const SizedBox(height: 10),

          Row(
            children: [
              Icon(
                Icons.place_outlined,
                size: 18,
                color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${b.ride.fromCity}  →  ${b.ride.toCity}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF232836) : const Color(0xFFE9EEF6),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
              ),
              const SizedBox(width: 6),
              Text(
                formatDateTime(b.ride.startTime),
                style: TextStyle(
                  color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                ),
              ),
              const SizedBox(width: 14),
              Icon(
                Icons.person_outline,
                size: 18,
                color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
              ),
              const SizedBox(width: 6),
              Text(
                shortId(b.ride.driverId),
                style: TextStyle(
                  color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: onDetails,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF232836)
                      : const Color(0xFFE2E6EF),
                ),
              ),
              child: const Text('Details'),
            ),
          ),
          if (showPay) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: isPaying ? null : onPay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.passengerPrimary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isDark
                      ? const Color(0xFF1C2331)
                      : const Color(0xFFE9EEF6),
                  disabledForegroundColor: isDark
                      ? AppColors.darkMuted
                      : const Color(0xFF9AA3B2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: isPaying
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        payButtonLabel,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ],
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
