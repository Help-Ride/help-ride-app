import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../controllers/driver_my_rides_controller.dart';
import 'ride_formatters.dart';

class DriverRideCard extends StatelessWidget {
  const DriverRideCard({super.key, required this.ride});
  final DriverRideItem ride;

  @override
  Widget build(BuildContext context) {
    final status = ride.status.toLowerCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final isPast = !ride.startTime.isAfter(DateTime.now());
    final canManage =
        !isPast && status != 'completed' && !status.contains('cancel');

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
                '\$${ride.pricePerSeat.toStringAsFixed(0)}/seat',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: textPrimary,
                ),
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
                  '${ride.from}  →  ${ride.to}',
                  softWrap: true,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 16, color: muted),
              const SizedBox(width: 6),
              Text(
                fmtDateTime(ride.startTime),
                style: TextStyle(color: muted),
              ),
              const SizedBox(width: 14),
              Icon(Icons.people_outline, size: 18, color: muted),
              const SizedBox(width: 6),
              Text(
                '${ride.booked}/${ride.seatsTotal} booked',
                style: TextStyle(color: muted),
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
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Get.toNamed('/driver/rides/${ride.id}'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text('Details'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: canManage
                      ? () => Get.toNamed('/driver/rides/${ride.id}/edit')
                      : null,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: canManage
                      ? () async {
                          final confirm = await Get.dialog<bool>(
                            Dialog(
                              insetPadding:
                                  const EdgeInsets.symmetric(horizontal: 22),
                              backgroundColor:
                                  isDark ? AppColors.darkSurface : const Color(0xFFF2F2F6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  22,
                                  22,
                                  22,
                                  18,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Cancel ride?',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 20,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'This will remove the ride for passengers.',
                                      style: TextStyle(
                                        color: muted,
                                      ),
                                    ),
                                    const SizedBox(height: 22),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () =>
                                              Get.back(result: false),
                                          child: const Text('Keep'),
                                        ),
                                        const SizedBox(width: 10),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Get.back(result: true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFFE53935),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 18,
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                            ),
                                          ),
                                          child: const Text('Cancel Ride'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            barrierDismissible: true,
                          );

                          if (confirm == true) {
                            Get.find<DriverMyRidesController>()
                                .cancelRide(ride.id);
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ],
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
    Color bg;
    Color fg;
    String text;

    if (status.contains('open')) {
      bg = const Color(0xFFEFF6FF);
      fg = const Color(0xFF2F6BFF);
      text = 'Open';
    } else if (status.contains('ongoing')) {
      bg = const Color(0xFFFFF2D6);
      fg = const Color(0xFFB86B00);
      text = 'Ongoing';
    } else if (status.contains('completed')) {
      bg = const Color(0xFFEFF2F6);
      fg = const Color(0xFF6B7280);
      text = 'Completed';
    } else if (status.contains('cancel')) {
      bg = const Color(0xFFFFE2E2);
      fg = const Color(0xFFD64545);
      text = 'Cancelled';
    } else {
      bg = const Color(0xFFEFF2F6);
      fg = const Color(0xFF6B7280);
      text = status;
    }

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
}
