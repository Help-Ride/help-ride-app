import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../home/widgets/common/app_card.dart';
import '../controllers/driver_home_controller.dart';
import '../routes/driver_routes.dart';
import '../services/driver_earnings_api.dart';

class DriverHomeView extends GetView<DriverHomeController> {
  const DriverHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Obx(() {
      final summary = controller.summary.value;
      final summaryLoading = controller.summaryLoading.value;
      final summaryError = controller.summaryError.value;

      final earnings = controller.earnings;
      final earningsLoading = controller.earningsLoading.value;
      final earningsError = controller.earningsError.value;
      final loadingMore = controller.loadingMore.value;
      final bottomSafeArea = MediaQuery.of(context).padding.bottom;

      final openRidesRaw = summary.ridesTotal - summary.ridesCompleted;
      final openRides = openRidesRaw < 0 ? 0 : openRidesRaw;

      return RefreshIndicator(
        onRefresh: controller.refreshAll,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: 28 + bottomSafeArea),
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 420;
                final buttonHeight = compact ? 52.0 : 54.0;
                final createButton = SizedBox(
                  height: buttonHeight,
                  child: ElevatedButton.icon(
                    onPressed: () => Get.toNamed(DriverRoutes.createRide),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.driverPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(
                      'Create a Ride',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                );

                final searchButton = SizedBox(
                  height: buttonHeight,
                  child: OutlinedButton.icon(
                    onPressed: () => Get.toNamed(DriverRoutes.rideRequests),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF111827)
                          : const Color(0xFFF3F8FF),
                      foregroundColor: AppColors.driverPrimary,
                      side: const BorderSide(
                        color: AppColors.driverPrimary,
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text(
                      'Search Ride',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                );

                if (compact) {
                  return Column(
                    children: [
                      SizedBox(width: double.infinity, child: createButton),
                      const SizedBox(height: 10),
                      SizedBox(width: double.infinity, child: searchButton),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: createButton),
                    const SizedBox(width: 10),
                    Expanded(child: searchButton),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final cardWidth = width >= 760
                    ? (width - 24) / 3
                    : width >= 340
                    ? (width - 12) / 2
                    : width;
                final compactCard = cardWidth < 210;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: _SummaryCard(
                        title: 'Rides',
                        value: summaryLoading
                            ? '...'
                            : '${summary.ridesCompleted}/${summary.ridesTotal}',
                        hint: summaryLoading
                            ? 'Loading rides...'
                            : '${summary.ridesCompleted} completed',
                        badgeText: summaryLoading ? null : '$openRides open',
                        compact: compactCard,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _SummaryCard(
                        title: 'Net Collected',
                        value: summaryLoading
                            ? '...'
                            : _formatCents(summary.netCollectedCents),
                        hint: summaryLoading
                            ? 'Loading earnings...'
                            : '${summary.paid.paymentsCount} paid payouts',
                        badgeText: summaryLoading
                            ? null
                            : '${summary.pending.paymentsCount} pending',
                        compact: compactCard,
                      ),
                    ),
                    if (width >= 760)
                      SizedBox(
                        width: cardWidth,
                        child: _SummaryCard(
                          title: 'Refunds + Failed',
                          value: summaryLoading
                              ? '...'
                              : '${summary.refunded.paymentsCount + summary.failed.paymentsCount}',
                          hint: summaryLoading
                              ? 'Loading status...'
                              : '${summary.refunded.paymentsCount} refunded · ${summary.failed.paymentsCount} failed',
                          badgeText: summaryLoading
                              ? null
                              : _formatCents(
                                  summary.refunded.amountCents +
                                      summary.failed.amountCents,
                                ),
                          compact: compactCard,
                        ),
                      ),
                  ],
                );
              },
            ),
            if (summaryError != null) ...[
              const SizedBox(height: 10),
              _InlineError(
                message: _normalizeError(summaryError),
                onRetry: controller.fetchSummary,
              ),
            ],
            if (!summaryLoading) ...[
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 390;
                  final chipWidth = compact
                      ? (constraints.maxWidth - 8) / 2
                      : null;

                  Widget chip(String label, String amount) {
                    final item = _AmountChip(label: label, amount: amount);
                    if (chipWidth == null) return item;
                    return SizedBox(width: chipWidth, child: item);
                  }

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      chip('Paid', _formatCents(summary.paid.amountCents)),
                      chip(
                        'Pending',
                        _formatCents(summary.pending.amountCents),
                      ),
                      chip(
                        'Refunded',
                        _formatCents(summary.refunded.amountCents),
                      ),
                      chip('Failed', _formatCents(summary.failed.amountCents)),
                    ],
                  );
                },
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Recent Earnings',
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      height: 1,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: controller.refreshAll,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (earningsLoading && earnings.isEmpty)
              const AppCard(
                child: SizedBox(
                  height: 88,
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (earningsError != null && earnings.isEmpty)
              AppCard(
                child: _EmptyLedgerState(
                  message: _normalizeError(earningsError),
                  actionLabel: 'Retry',
                  onAction: () => controller.fetchEarnings(reset: true),
                ),
              )
            else if (earnings.isEmpty)
              AppCard(
                child: _EmptyLedgerState(
                  message: 'No succeeded earnings yet.',
                  actionLabel: 'Refresh',
                  onAction: controller.refreshAll,
                ),
              )
            else ...[
              ...earnings.map(
                (payment) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _EarningTile(payment: payment),
                ),
              ),
              if (earningsError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _InlineError(
                    message: _normalizeError(earningsError),
                    onRetry: () => controller.fetchEarnings(reset: true),
                  ),
                ),
              if (controller.hasMoreEarnings || loadingMore)
                Center(
                  child: TextButton.icon(
                    onPressed: loadingMore ? null : controller.loadMoreEarnings,
                    icon: loadingMore
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.expand_more_rounded),
                    label: Text(loadingMore ? 'Loading...' : 'Load more'),
                  ),
                ),
            ],
            if (earnings.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Showing succeeded payments only',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.hint,
    this.badgeText,
    this.compact = false,
  });

  final String title;
  final String value;
  final String hint;
  final String? badgeText;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final badgeBg = AppColors.driverPrimary.withValues(
      alpha: isDark ? 0.22 : 0.12,
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: compact ? 15 : 16,
            ),
          ),
          SizedBox(height: compact ? 8 : 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: compact ? 28 : 34,
              height: 1,
            ),
          ),
          SizedBox(height: compact ? 6 : 8),
          Text(
            hint,
            maxLines: compact ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: muted,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 13 : 14,
            ),
          ),
          if (badgeText != null && badgeText!.trim().isNotEmpty) ...[
            SizedBox(height: compact ? 10 : 12),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 10,
                vertical: compact ? 5 : 6,
              ),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badgeText!,
                style: TextStyle(
                  color: AppColors.driverPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 11 : 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  const _AmountChip({required this.label, required this.amount});

  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A2233) : const Color(0xFFEAF2FF);
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                color: muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: amount,
              style: TextStyle(
                color: textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EarningTile extends StatelessWidget {
  const _EarningTile({required this.payment});

  final DriverEarningPayment payment;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    final ride = payment.booking?.ride;
    final passengerName = payment.booking?.passenger?.name.trim();

    final fromCity = (ride?.fromCity ?? '').trim();
    final toCity = (ride?.toCity ?? '').trim();
    final compactFromLine = _compactAddress(fromCity);
    final compactToLine = _compactAddress(toCity);
    final fromLine = fromCity.isEmpty ? compactFromLine : fromCity;
    final toLine = toCity.isEmpty ? compactToLine : toCity;
    final shortRoute = _routeLabel(from: compactFromLine, to: compactToLine);
    final longRoute = _routeLabel(from: fromCity, to: toCity);

    final amount = _formatCents(
      payment.driverEarningsCents,
      currency: payment.currency,
    );
    final gross = _formatCents(payment.amountCents, currency: payment.currency);
    final fee = _formatCents(
      payment.platformFeeCents,
      currency: payment.currency,
    );

    final tripTime = ride?.startTime ?? payment.createdAt ?? payment.updatedAt;

    return GestureDetector(
      onTap: () => _showPaymentDetails(
        context,
        payment: payment,
        shortRoute: shortRoute,
        longRoute: longRoute,
      ),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RouteLine(
                        icon: Icons.trip_origin,
                        iconColor: muted,
                        text: fromLine.isEmpty
                            ? 'Pickup unavailable'
                            : fromLine,
                        textColor: textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        maxLines: null,
                      ),
                      const SizedBox(height: 2),
                      _RouteLine(
                        icon: Icons.location_on_outlined,
                        iconColor: muted,
                        text: toLine.isEmpty ? 'Dropoff unavailable' : toLine,
                        textColor: textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        maxLines: null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  amount,
                  style: const TextStyle(
                    color: AppColors.driverPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Passenger: ',
                    style: TextStyle(
                      color: muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  TextSpan(
                    text: (passengerName == null || passengerName.isEmpty)
                        ? 'Passenger'
                        : passengerName,
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _StatusChip(status: payment.status),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatDateTime(tripTime),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Gross $gross  •  Fee $fee',
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.textColor,
    required this.fontWeight,
    required this.fontSize,
    required this.maxLines,
  });

  final IconData icon;
  final Color iconColor;
  final String text;
  final Color textColor;
  final FontWeight fontWeight;
  final double fontSize;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 15, color: iconColor),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            softWrap: true,
            style: TextStyle(
              color: textColor,
              fontWeight: fontWeight,
              fontSize: fontSize,
              height: 1.15,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final normalized = status.trim().toLowerCase();

    final color = switch (normalized) {
      'succeeded' => AppColors.driverPrimary,
      'paid' => AppColors.driverPrimary,
      'pending' => const Color(0xFFE29B00),
      'failed' => AppColors.error,
      'refunded' => const Color(0xFF9B59B6),
      _ => isDark ? AppColors.darkMuted : AppColors.lightMuted,
    };
    final bg = color.withValues(alpha: isDark ? 0.2 : 0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        normalized.isEmpty ? 'UNKNOWN' : normalized.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyLedgerState extends StatelessWidget {
  const _EmptyLedgerState({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    return Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: muted),
        ),
        const SizedBox(height: 10),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.error_outline, color: AppColors.error, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _SheetDetailRow extends StatelessWidget {
  const _SheetDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 98,
            child: Text(
              label,
              style: TextStyle(
                color: muted,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showPaymentDetails(
  BuildContext context, {
  required DriverEarningPayment payment,
  required String shortRoute,
  required String longRoute,
}) async {
  final booking = payment.booking;
  final ride = booking?.ride;
  final passenger = booking?.passenger;

  final displayRoute = longRoute.trim().isEmpty ? shortRoute : longRoute;
  final bookingId = booking?.id.trim() ?? '';
  final paymentIntentId = payment.paymentIntentId.trim();
  final paymentId = payment.id.trim();
  final status = payment.status.trim().isEmpty
      ? 'unknown'
      : payment.status.trim().toLowerCase();
  final gross = _formatCents(payment.amountCents, currency: payment.currency);
  final fee = _formatCents(
    payment.platformFeeCents,
    currency: payment.currency,
  );
  final net = _formatCents(
    payment.driverEarningsCents,
    currency: payment.currency,
  );
  final seats = booking?.seatsBooked ?? 0;
  final rideTime = ride?.startTime ?? payment.createdAt ?? payment.updatedAt;
  final passengerName = passenger?.name.trim() ?? '';
  final passengerEmail = passenger?.email.trim() ?? '';
  final passengerDisplay = passengerName.isEmpty ? 'Passenger' : passengerName;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
      final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
      final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;

      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: muted.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Earning Details',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                displayRoute,
                style: TextStyle(
                  color: muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              _StatusChip(status: status),
              const SizedBox(height: 14),
              _SheetDetailRow(label: 'Driver net', value: net),
              _SheetDetailRow(label: 'Gross', value: gross),
              _SheetDetailRow(label: 'Platform fee', value: fee),
              _SheetDetailRow(
                label: 'Trip time',
                value: _formatDateTime(rideTime),
              ),
              _SheetDetailRow(label: 'Passenger', value: passengerDisplay),
              if (passengerEmail.isNotEmpty)
                _SheetDetailRow(
                  label: 'Passenger email',
                  value: passengerEmail,
                ),
              if (seats > 0) _SheetDetailRow(label: 'Seats', value: '$seats'),
              if (bookingId.isNotEmpty)
                _SheetDetailRow(label: 'Booking ID', value: bookingId),
              if (paymentId.isNotEmpty)
                _SheetDetailRow(label: 'Payment ID', value: paymentId),
              if (paymentIntentId.isNotEmpty)
                _SheetDetailRow(label: 'Intent ID', value: paymentIntentId),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    },
  );
}

String _compactAddress(String location) {
  final raw = location.trim();
  if (raw.isEmpty) return '';

  final parts = raw
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return raw;

  final lowerLast = parts.isEmpty ? '' : parts.last.toLowerCase();
  if (lowerLast == 'usa' ||
      lowerLast == 'united states' ||
      lowerLast == 'canada') {
    parts.removeLast();
  }

  if (parts.length >= 3) {
    return '${parts[0]}, ${parts[1]}, ${parts[2]}';
  }
  if (parts.length == 2) {
    return '${parts[0]}, ${parts[1]}';
  }
  return parts.first;
}

String _routeLabel({required String from, required String to}) {
  final left = from.trim();
  final right = to.trim();
  if (left.isNotEmpty && right.isNotEmpty) return '$left -> $right';
  if (left.isNotEmpty) return left;
  if (right.isNotEmpty) return right;
  return 'Route unavailable';
}

String _formatCents(int cents, {String currency = 'CAD'}) {
  final sign = cents < 0 ? '-' : '';
  final absolute = cents.abs();
  final dollars = absolute ~/ 100;
  final centsPart = (absolute % 100).toString().padLeft(2, '0');

  final upper = currency.trim().toUpperCase();
  final prefix = switch (upper) {
    'USD' => '\$',
    'CAD' => 'CA\$',
    '' => '\$',
    _ => '$upper ',
  };

  return '$sign$prefix$dollars.$centsPart';
}

String _formatDateTime(DateTime? date) {
  if (date == null) return 'Unknown date';
  final local = date.toLocal();
  const months = <String>[
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
  final month = months[local.month - 1];
  final minute = local.minute.toString().padLeft(2, '0');
  final hour24 = local.hour;
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final suffix = hour24 >= 12 ? 'PM' : 'AM';
  return '$month ${local.day}, ${local.year} · $hour12:$minute $suffix';
}

String _normalizeError(String raw) {
  var result = raw.trim();
  if (result.startsWith('Exception:')) {
    result = result.substring('Exception:'.length).trim();
  }
  if (result.isEmpty) return 'Something went wrong.';
  return result;
}
