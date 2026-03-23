import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../rides/utils/ride_recurrence.dart';
import '../controllers/driver_ride_series_controller.dart';
import '../models/driver_ride_management.dart';
import '../widgets/my_rides/driver_ride_bookings_sheet.dart';
import '../widgets/my_rides/ride_formatters.dart';
import '../widgets/my_rides/ride_scope_sheet.dart';

class DriverRideSeriesView extends GetView<DriverRideSeriesController> {
  const DriverRideSeriesView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: textPrimary,
        title: const Text(
          'Recurring Series',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.loading.value && controller.series.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.series.value == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      controller.error.value ?? 'Recurring series not found.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: controller.fetch,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final series = controller.series.value!;
          final occurrences = controller.filteredOccurrences;
          return RefreshIndicator(
            onRefresh: controller.fetch,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
              children: [
                _SeriesHeaderCard(
                  series: series,
                  muted: muted,
                  textPrimary: textPrimary,
                  onEditSeries: () => _openSeriesEdit(context, series),
                ),
                const SizedBox(height: 18),
                Text(
                  'Occurrences',
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Track upcoming occurrences here. Modified and cancelled rides are highlighted.',
                  style: TextStyle(color: muted),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => _OccurrenceFilters(
                    active: controller.occurrenceFilter.value,
                    onChange: controller.setOccurrenceFilter,
                  ),
                ),
                const SizedBox(height: 12),
                if (occurrences.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF232836)
                            : const Color(0xFFE6EAF2),
                      ),
                    ),
                    child: Text(
                      'No occurrences match this filter.',
                      style: TextStyle(color: muted),
                    ),
                  )
                else
                  ...occurrences.map(
                    (ride) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _OccurrenceCard(
                        ride: ride,
                        isModified: series.isModifiedOccurrence(ride),
                        onViewDetails: () => showDriverRideBookingsSheet(
                          context,
                          rideId: ride.id,
                          ride: ride,
                        ),
                        onEdit: () => Get.toNamed(
                          '/driver/rides/${ride.id}/edit',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Future<void> _openSeriesEdit(
    BuildContext context,
    DriverRideSeriesSummary series,
  ) async {
    final anchorRide = series.nextUpcomingOccurrence ?? series.anchorRide;
    final scope = await showRideScopeSheet(
      context: context,
      title: 'Edit recurring schedule',
      subtitle:
          'Choose whether to update future rides from this point or the entire series.',
      includeOccurrence: false,
      recommendedScope: 'future',
    );
    if (scope == null) return;

    await Get.toNamed(
      '/driver/rides/${anchorRide.id}/edit',
      arguments: {
        'editScope': scope,
        'seriesId': series.id,
      },
    );
    await controller.fetch();
  }
}

class _SeriesHeaderCard extends StatelessWidget {
  const _SeriesHeaderCard({
    required this.series,
    required this.muted,
    required this.textPrimary,
    required this.onEditSeries,
  });

  final DriverRideSeriesSummary series;
  final Color muted;
  final Color textPrimary;
  final VoidCallback onEditSeries;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF232836) : const Color(0xFFE6EAF2),
        ),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.driverPrimary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        series.lifecycleLabel,
                        style: const TextStyle(
                          color: AppColors.driverPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF3F5F8),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Recurring series',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFFBFDBFE)
                              : const Color(0xFF475569),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
              _InfoChip(
                icon: Icons.repeat_rounded,
                label: 'Every ${formatRideRecurrenceDays(series.recurrenceDays)}',
                muted: muted,
                isDark: isDark,
              ),
              _InfoChip(
                icon: Icons.event_note_rounded,
                label: fmtDateRange(
                  series.startDate,
                  series.recurrenceEndDate ?? series.endDate,
                ),
                muted: muted,
                isDark: isDark,
              ),
              _InfoChip(
                icon: Icons.schedule_rounded,
                label: series.nextUpcomingOccurrence == null
                    ? 'No upcoming ride'
                    : 'Next ${fmtDateTime(series.nextUpcomingOccurrence!.startTime)}',
                muted: muted,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SummaryGrid(
            series: series,
            muted: muted,
            textPrimary: textPrimary,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFD),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF232836)
                    : const Color(0xFFE6EAF2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: muted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Routine occurrences stay quiet here. Focus on modified, cancelled, or booked rides when reviewing the series.',
                    style: TextStyle(
                      color: muted,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onEditSeries,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.driverPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Edit Series'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OccurrenceFilters extends StatelessWidget {
  const _OccurrenceFilters({
    required this.active,
    required this.onChange,
  });

  final DriverRideOccurrenceFilter active;
  final ValueChanged<DriverRideOccurrenceFilter> onChange;

  @override
  Widget build(BuildContext context) {
    final options = <(DriverRideOccurrenceFilter, String)>[
      (DriverRideOccurrenceFilter.all, 'All'),
      (DriverRideOccurrenceFilter.upcoming, 'Upcoming'),
      (DriverRideOccurrenceFilter.modified, 'Modified'),
      (DriverRideOccurrenceFilter.cancelled, 'Cancelled'),
      (DriverRideOccurrenceFilter.completed, 'Completed'),
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final selected = active == option.$1;
        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => onChange(option.$1),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.driverPrimary.withValues(alpha: 0.12)
                  : (isDark ? const Color(0xFF111827) : Colors.white),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? AppColors.driverPrimary
                    : (isDark
                          ? const Color(0xFF232836)
                          : const Color(0xFFE1E7F0)),
              ),
            ),
            child: Text(
              option.$2,
              style: TextStyle(
                color: selected
                    ? AppColors.driverPrimary
                    : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _OccurrenceCard extends StatelessWidget {
  const _OccurrenceCard({
    required this.ride,
    required this.isModified,
    required this.onViewDetails,
    required this.onEdit,
  });

  final DriverRideItem ride;
  final bool isModified;
  final VoidCallback onViewDetails;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final canEdit = !ride.isCancelled && !ride.isCompleted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF232836) : const Color(0xFFE6EAF2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  fmtDateTime(ride.startTime),
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  if (isModified)
                    _OccurrenceFlag(
                      label: 'Modified',
                      background: AppColors.driverPrimary.withValues(alpha: 0.12),
                      foreground: AppColors.driverPrimary,
                    ),
                  _OccurrenceStatusPill(status: ride.status),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _RoutePanel(
            from: ride.from,
            to: ride.to,
            textPrimary: textPrimary,
            muted: muted,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _OccurrenceChip(
                icon: Icons.event_seat_outlined,
                label: '${ride.booked}/${ride.seatsTotal} booked',
                muted: muted,
                isDark: isDark,
              ),
              _OccurrenceChip(
                icon: Icons.attach_money_rounded,
                label: '${fmtPrice(ride.pricePerSeat)}/seat',
                muted: muted,
                isDark: isDark,
              ),
              if (ride.arrivalTime != null)
                _OccurrenceChip(
                  icon: Icons.flag_outlined,
                  label: 'Arrives ${fmtDateTime(ride.arrivalTime!)}',
                  muted: muted,
                  isDark: isDark,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onViewDetails,
                  child: const Text('Details'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: canEdit ? onEdit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.driverPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  child: const Text('Edit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OccurrenceChip extends StatelessWidget {
  const _OccurrenceChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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

class _OccurrenceFlag extends StatelessWidget {
  const _OccurrenceFlag({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
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
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _OccurrenceStatusPill extends StatelessWidget {
  const _OccurrenceStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final background = normalized.contains('cancel')
        ? const Color(0xFFFDECEC)
        : normalized.contains('complete')
        ? const Color(0xFFEFF2F6)
        : normalized.contains('ongoing')
        ? const Color(0xFFEAF3FF)
        : const Color(0xFFE7F8EF);
    final foreground = normalized.contains('cancel')
        ? const Color(0xFFC5394D)
        : normalized.contains('complete')
        ? const Color(0xFF64748B)
        : normalized.contains('ongoing')
        ? const Color(0xFF2563EB)
        : const Color(0xFF179C5E);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        normalized.contains('cancel')
            ? 'Cancelled'
            : normalized.contains('complete')
            ? 'Completed'
            : normalized.contains('ongoing')
            ? 'Ongoing'
            : 'Scheduled',
        style: TextStyle(color: foreground, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.series,
    required this.muted,
    required this.textPrimary,
    required this.isDark,
  });

  final DriverRideSeriesSummary series;
  final Color muted;
  final Color textPrimary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final items = <({String label, String value, bool highlight})>[
      (label: 'Total', value: '${series.totalOccurrences}', highlight: false),
      (label: 'Upcoming', value: '${series.upcomingCount}', highlight: false),
      (
        label: 'Modified',
        value: '${series.modifiedCount}',
        highlight: series.modifiedCount > 0,
      ),
      (
        label: 'Cancelled',
        value: '${series.cancelledCount}',
        highlight: series.cancelledCount > 0,
      ),
      (label: 'Completed', value: '${series.completedCount}', highlight: false),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map(
                (item) => SizedBox(
                  width: tileWidth,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF111827)
                          : const Color(0xFFF7F9FC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF232836)
                            : const Color(0xFFE6EAF2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: TextStyle(
                            color: muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.value,
                          style: TextStyle(
                            color: item.highlight
                                ? AppColors.driverPrimary
                                : textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
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
