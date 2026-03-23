import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../rides/utils/ride_recurrence.dart';
import '../../models/driver_ride_management.dart';
import 'ride_formatters.dart';

class DriverRecurringSeriesCard extends StatelessWidget {
  const DriverRecurringSeriesCard({
    super.key,
    required this.series,
    required this.onViewSeries,
    required this.onEditSeries,
  });

  final DriverRideSeriesSummary series;
  final VoidCallback onViewSeries;
  final VoidCallback onEditSeries;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final upcomingRide = series.nextUpcomingOccurrence;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF232836) : const Color(0xFFE6EAF2),
        ),
        boxShadow: isDark
            ? const []
            : const [
                BoxShadow(
                  blurRadius: 24,
                  offset: Offset(0, 12),
                  color: Color(0x0A000000),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SeriesStatusPill(label: series.lifecycleLabel, isDark: isDark),
                    _MetaPill(
                      text: 'Recurring',
                      background: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF3F5F8),
                      foreground: isDark
                          ? const Color(0xFFBFDBFE)
                          : const Color(0xFF475569),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${fmtPrice(series.pricePerSeat)}/seat',
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${series.seatCapacity} seats',
                    style: TextStyle(
                      color: muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _RoutePanel(
            from: series.from,
            to: series.to,
            textPrimary: textPrimary,
            muted: muted,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricChip(
                icon: Icons.repeat_rounded,
                label: 'Every ${formatRideRecurrenceDays(series.recurrenceDays)}',
                muted: muted,
                isDark: isDark,
              ),
              _MetricChip(
                icon: Icons.event_note_rounded,
                label: fmtDateRange(
                  series.startDate,
                  series.recurrenceEndDate ?? series.endDate,
                ),
                muted: muted,
                isDark: isDark,
              ),
              _MetricChip(
                icon: Icons.schedule_rounded,
                label: upcomingRide == null
                    ? 'No upcoming ride'
                    : 'Next ${fmtDateTime(upcomingRide.startTime)}',
                muted: muted,
                isDark: isDark,
              ),
              _MetricChip(
                icon: Icons.event_repeat_outlined,
                label:
                    '${series.upcomingCount} upcoming occurrence${series.upcomingCount == 1 ? '' : 's'}',
                muted: muted,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SeriesStatGrid(
            stats: [
              _SeriesStatData(label: 'Total', value: '${series.totalOccurrences}'),
              _SeriesStatData(label: 'Upcoming', value: '${series.upcomingCount}'),
              _SeriesStatData(
                label: 'Modified',
                value: '${series.modifiedCount}',
                highlight: series.modifiedCount > 0,
              ),
              _SeriesStatData(
                label: 'Cancelled',
                value: '${series.cancelledCount}',
                highlight: series.cancelledCount > 0,
              ),
            ],
            muted: muted,
            textPrimary: textPrimary,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onViewSeries,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text('View Series'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onEditSeries,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: AppColors.driverPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text('Edit Series'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoutePanel extends StatelessWidget {
  const _RoutePanel({
    required this.from,
    required this.to,
    required this.textPrimary,
    required this.muted,
    required this.isDark,
  });

  final String from;
  final String to;
  final Color textPrimary;
  final Color muted;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF232836) : const Color(0xFFE6EAF2),
        ),
      ),
      child: Column(
        children: [
          _RouteStopRow(
            icon: Icons.radio_button_checked_rounded,
            iconColor: AppColors.driverPrimary,
            label: 'Pickup',
            primary: compactAddress(from),
            secondary: compactAddressMeta(from),
            textPrimary: textPrimary,
            muted: muted,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(
              height: 1,
              color: isDark ? const Color(0xFF232836) : const Color(0xFFE6EAF2),
            ),
          ),
          _RouteStopRow(
            icon: Icons.location_on_outlined,
            iconColor: const Color(0xFF2563EB),
            label: 'Drop-off',
            primary: compactAddress(to),
            secondary: compactAddressMeta(to),
            textPrimary: textPrimary,
            muted: muted,
          ),
        ],
      ),
    );
  }
}

class _RouteStopRow extends StatelessWidget {
  const _RouteStopRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.primary,
    required this.secondary,
    required this.textPrimary,
    required this.muted,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String primary;
  final String secondary;
  final Color textPrimary;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                primary,
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  height: 1.2,
                ),
              ),
              if (secondary.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  secondary,
                  style: TextStyle(
                    color: muted,
                    fontSize: 13,
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

class _SeriesStatusPill extends StatelessWidget {
  const _SeriesStatusPill({required this.label, required this.isDark});

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg = switch (label) {
      'Active' => isDark ? const Color(0xFF123126) : const Color(0xFFE7F8EF),
      'Paused' => isDark ? const Color(0xFF332714) : const Color(0xFFFFF4E6),
      _ => isDark ? const Color(0xFF1F2937) : const Color(0xFFEFF2F6),
    };
    final fg = switch (label) {
      'Active' => const Color(0xFF179C5E),
      'Paused' => const Color(0xFFB96A12),
      _ => isDark ? AppColors.darkMuted : AppColors.lightMuted,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.muted,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final Color muted;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark ? const Color(0xFF232836) : const Color(0xFFE6EAF2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: muted),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: muted,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeriesStatGrid extends StatelessWidget {
  const _SeriesStatGrid({
    required this.stats,
    required this.muted,
    required this.textPrimary,
    required this.isDark,
  });

  final List<_SeriesStatData> stats;
  final Color muted;
  final Color textPrimary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: stats
              .map(
                (stat) => SizedBox(
                  width: tileWidth,
                  child: _SummaryMetric(
                    label: stat.label,
                    value: stat.value,
                    muted: muted,
                    textPrimary: textPrimary,
                    isDark: isDark,
                    highlight: stat.highlight,
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.muted,
    required this.textPrimary,
    required this.isDark,
    this.highlight = false,
  });

  final String label;
  final String value;
  final Color muted;
  final Color textPrimary;
  final bool isDark;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF232836) : const Color(0xFFE6EAF2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: highlight ? AppColors.driverPrimary : textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              height: 1,
            ),
          ),
        ],
      ),
    );
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

class _SeriesStatData {
  const _SeriesStatData({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;
}
