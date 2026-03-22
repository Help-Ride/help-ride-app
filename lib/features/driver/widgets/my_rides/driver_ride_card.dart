import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../rides/utils/ride_recurrence.dart';
import '../../models/driver_ride_management.dart';
import 'ride_formatters.dart';

class DriverRideCard extends StatelessWidget {
  const DriverRideCard({
    super.key,
    required this.ride,
    required this.onViewDetails,
    required this.onEdit,
    required this.onCancel,
  });

  final DriverRideItem ride;
  final VoidCallback onViewDetails;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

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
            ? const []
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
              if (ride.isRecurring) ...[
                const SizedBox(width: 8),
                _MetaPill(
                  text: 'Recurring occurrence',
                  background: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF3F5F8),
                  foreground: isDark
                      ? const Color(0xFFBFDBFE)
                      : const Color(0xFF475569),
                ),
              ],
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
                  ride.routeLabel,
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
              Text(fmtDateTime(ride.startTime), style: TextStyle(color: muted)),
              const SizedBox(width: 14),
              Icon(Icons.people_outline, size: 18, color: muted),
              const SizedBox(width: 6),
              Text(
                '${ride.booked}/${ride.seatsTotal} booked',
                style: TextStyle(color: muted),
              ),
            ],
          ),
          if (ride.isRecurring) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.repeat_rounded, size: 16, color: muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Repeats ${formatRideRecurrenceDays(ride.recurrenceDays)}'
                    '${ride.recurrenceEndDate == null ? '' : ' until ${_fmtSeriesDate(ride.recurrenceEndDate!)}'}',
                    style: TextStyle(color: muted),
                  ),
                ),
              ],
            ),
          ],
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
                  onPressed: onViewDetails,
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
                  onPressed: canManage ? onEdit : null,
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
                  onPressed: canManage ? onCancel : null,
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
    final isCancelled = status.contains('cancel');
    final isCompleted = status.contains('complete');
    final isOngoing = status.contains('ongoing');

    final background = isCancelled
        ? const Color(0xFFFDECEC)
        : isCompleted
        ? const Color(0xFFEFF2F6)
        : isOngoing
        ? const Color(0xFFEAF3FF)
        : const Color(0xFFE7F8EF);
    final foreground = isCancelled
        ? const Color(0xFFC5394D)
        : isCompleted
        ? const Color(0xFF64748B)
        : isOngoing
        ? const Color(0xFF2563EB)
        : const Color(0xFF179C5E);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _title(status),
        style: TextStyle(color: foreground, fontWeight: FontWeight.w800),
      ),
    );
  }

  String _title(String value) {
    if (value.contains('cancel')) return 'Cancelled';
    if (value.contains('complete')) return 'Completed';
    if (value.contains('ongoing')) return 'Ongoing';
    return 'Open';
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
      ),
    );
  }
}

String _fmtSeriesDate(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[value.month - 1]} ${value.day}';
}
