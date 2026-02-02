import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';

class DriverActiveRideView extends StatelessWidget {
  const DriverActiveRideView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = (Get.arguments is Map)
        ? (Get.arguments as Map).cast<String, dynamic>()
        : const <String, dynamic>{};

    final pickup = _read(args, 'pickupAddress', 'pickup_address');
    final dropoff = _read(args, 'dropoffAddress', 'dropoff_address');
    final rideRequestId = _read(args, 'rideRequestId', 'ride_request_id');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: textPrimary,
        title: const Text(
          'Active Ride',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF232836)
                        : const Color(0xFFE6EAF2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label(text: 'Pickup'),
                    const SizedBox(height: 4),
                    Text(
                      pickup.isEmpty ? 'Pickup location' : pickup,
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _Label(text: 'Dropoff'),
                    const SizedBox(height: 4),
                    Text(
                      dropoff.isEmpty ? 'Dropoff location' : dropoff,
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    if (rideRequestId.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Ride request: $rideRequestId',
                        style: TextStyle(
                          color: muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Ride accepted. Continue in your normal driver workflow.',
                  style: TextStyle(
                    color: AppColors.driverPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Get.offAllNamed('/shell'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.driverPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Back to Dashboard',
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

  String _read(Map<String, dynamic> data, String camel, String snake) {
    return (data[camel] ?? data[snake] ?? '').toString().trim();
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    return Text(
      text,
      style: TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w700),
    );
  }
}
