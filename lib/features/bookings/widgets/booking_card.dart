import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/booking.dart';
import '../utils/booking_formatters.dart';

class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.b,
    this.showPay = false,
    this.showCancel = false,
    this.isPaying = false,
    this.isCanceling = false,
    this.payButtonLabel = 'Pay now',
    this.paymentStateLabel,
    this.onPay,
    this.onCancel,
    this.onDetails,
  });

  final Booking b;
  final bool showPay;
  final bool showCancel;
  final bool isPaying;
  final bool isCanceling;
  final String payButtonLabel;
  final String? paymentStateLabel;
  final VoidCallback? onPay;
  final VoidCallback? onCancel;
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) {
    final status = b.status.toLowerCase();
    final driverName = (b.ride.driver?.name ?? '').trim();
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
              StatusPill(status: status, paymentStatus: b.paymentStatus),
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

          _BookingRoutePanel(
            isDark: isDark,
            pickupName: b.pickupLabel,
            pickupLat: b.passengerPickupLat,
            pickupLng: b.passengerPickupLng,
            dropoffName: b.dropoffLabel,
            dropoffLat: b.passengerDropoffLat,
            dropoffLng: b.passengerDropoffLng,
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
                driverName.isNotEmpty ? driverName : shortId(b.ride.driverId),
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
          if (showCancel) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: isCanceling ? null : onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isCanceling
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Cancel Booking',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ],
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

class _BookingRoutePanel extends StatelessWidget {
  const _BookingRoutePanel({
    required this.isDark,
    required this.pickupName,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffName,
    required this.dropoffLat,
    required this.dropoffLng,
  });

  final bool isDark;
  final String pickupName;
  final double? pickupLat;
  final double? pickupLng;
  final String dropoffName;
  final double? dropoffLat;
  final double? dropoffLng;

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final panelBg = isDark ? const Color(0xFF1C2331) : const Color(0xFFF7F9FC);
    final panelBorder = isDark
        ? const Color(0xFF232836)
        : const Color(0xFFE6EAF2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pickup & drop-off',
            style: TextStyle(
              color: muted,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          _BookingLocationRow(
            isDark: isDark,
            icon: Icons.my_location_outlined,
            label: 'Pickup',
            name: pickupName,
            lat: pickupLat,
            lng: pickupLng,
          ),
          const SizedBox(height: 10),
          _BookingLocationRow(
            isDark: isDark,
            icon: Icons.place_outlined,
            label: 'Drop-off',
            name: dropoffName,
            lat: dropoffLat,
            lng: dropoffLng,
            iconColor: AppColors.passengerPrimary,
          ),
        ],
      ),
    );
  }
}

class _BookingLocationRow extends StatelessWidget {
  const _BookingLocationRow({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.name,
    required this.lat,
    required this.lng,
    this.iconColor,
  });

  final bool isDark;
  final IconData icon;
  final String label;
  final String name;
  final double? lat;
  final double? lng;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final coords = _coordsText(lat, lng);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 18, color: iconColor ?? muted),
        ),
        const SizedBox(width: 10),
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
                name.trim().isEmpty ? 'Not provided' : name,
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              if (coords != null) ...[
                const SizedBox(height: 2),
                Text(
                  coords,
                  style: TextStyle(
                    color: muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

String? _coordsText(double? lat, double? lng) {
  if (lat == null || lng == null) return null;
  return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status, this.paymentStatus});
  final String status;
  final String? paymentStatus;

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
    final isPaid = isPaymentPaidStatus(paymentStatus ?? '');

    if (s.contains('confirm') || isPaid) {
      return (const Color(0xFFE7F8EF), const Color(0xFF179C5E), 'Confirmed');
    }
    if (s.contains('accept')) {
      return (const Color(0xFFFFF2D6), const Color(0xFFB86B00), 'Accepted');
    }
    if (s.contains('pending') || s.contains('request')) {
      return (const Color(0xFFFFF2D6), const Color(0xFFB86B00), 'Pending');
    }
    if (s.contains('reject')) {
      return (const Color(0xFFFFE2E2), const Color(0xFFD64545), 'Rejected');
    }
    if (s.contains('cancel')) {
      return (const Color(0xFFFFE2E2), const Color(0xFFD64545), 'Cancelled');
    }
    if (s.contains('completed')) {
      return (const Color(0xFFEFF2F6), const Color(0xFF6B7280), 'Completed');
    }
    return (const Color(0xFFEFF2F6), const Color(0xFF6B7280), s);
  }
}
