import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';

class BookingSuccessView extends StatelessWidget {
  const BookingSuccessView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = (Get.arguments as Map?) ?? {};
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    final route = (args['route'] ?? '').toString();
    final departure = (args['departure'] ?? '').toString();
    final status = (args['status'] ?? 'pending').toString().toLowerCase();
    final isConfirmed = status.contains('confirm') || status.contains('accept');
    final ref = (args['ref'] ?? '').toString();

    final totalRaw = args['total'];
    final total = totalRaw is num
        ? totalRaw.toDouble()
        : double.tryParse('$totalRaw') ?? 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                height: 84,
                width: 84,
                decoration: const BoxDecoration(
                  color: AppColors.passengerPrimary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isConfirmed ? Icons.check : Icons.schedule,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isConfirmed ? 'Booking Confirmed!' : 'Request Sent!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isConfirmed
                    ? 'Your ride is confirmed. The driver will contact you soon.'
                    : 'Waiting for the driver to accept your request. You’ll be notified soon.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, height: 1.4),
              ),

              const SizedBox(height: 20),

              _Card(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking Details',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    _DetailRow(
                      icon: Icons.place,
                      iconBg: const Color(0xFFE7F8EF),
                      label: 'Route',
                      value: route.isEmpty ? '-' : route,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.access_time,
                      iconBg: const Color(0xFFEFF6FF),
                      label: 'Departure',
                      value: departure.isEmpty ? '-' : departure,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.attach_money,
                      iconBg: const Color(0xFFF3ECFF),
                      label: 'Total Price',
                      value: '\$${total.toStringAsFixed(0)}',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _Card(
                isDark: isDark,
                child: Column(
                  children: [
                    Text(
                      'Booking Reference',
                      style: TextStyle(
                        color: muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      ref.isEmpty ? '-' : ref,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.toNamed('/my-rides'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.passengerPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    isConfirmed ? 'View My Rides' : 'View My Requests',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Get.offAllNamed('/'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: BorderSide(
                      color: isDark
                          ? const Color(0xFF232836)
                          : const Color(0xFFE2E6EF),
                    ),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, required this.isDark});
  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: child,
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.isDark,
  });

  final IconData icon;
  final Color iconBg;
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 18,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
