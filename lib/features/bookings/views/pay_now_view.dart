import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/my_rides_controller.dart';
import '../models/booking.dart';
import '../utils/booking_formatters.dart';

class BookingPayNowView extends GetView<MyRidesController> {
  const BookingPayNowView({super.key});

  @override
  Widget build(BuildContext context) {
    final booking = _readBooking();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pay Now')),
        body: const Center(child: Text('Missing booking details.')),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: const Text(
          'Pay Now',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            children: [
              _SummaryCard(booking: booking, isDark: isDark),
              const SizedBox(height: 12),
              Obx(() {
                final session = controller.paymentSessionForBooking(booking.id);
                final intentId =
                    controller.paymentIntentIdForBooking(booking.id) ??
                    booking.paymentIntentId;
                if (intentId == null || intentId.trim().isEmpty) {
                  return const SizedBox.shrink();
                }
                return _IntentCard(
                  intentId: intentId,
                  amount: session?.amount,
                  currency: session?.currency,
                  isDark: isDark,
                );
              }),
              const Spacer(),
              Obx(() {
                final paying = controller.isPaying(booking.id);
                final payLabel = controller.payButtonLabel(booking);
                return SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: paying
                        ? null
                        : () async {
                            final result = await controller.payToConfirm(
                              booking,
                            );
                            if (result == PaymentAttemptResult.processing) {
                              if (Get.key.currentState?.canPop() ?? false) {
                                Get.back();
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.passengerPrimary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: isDark
                          ? const Color(0xFF1C2331)
                          : const Color(0xFFE9EEF6),
                      disabledForegroundColor: isDark
                          ? AppColors.darkMuted
                          : const Color(0xFF9AA3B2),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: paying
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            payLabel,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Booking? _readBooking() {
    final args = Get.arguments;
    if (args is Booking) return args;
    if (args is Map && args['booking'] is Booking) {
      return args['booking'] as Booking;
    }
    return null;
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.booking, required this.isDark});

  final Booking booking;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${booking.pickupLabel} \u2192 ${booking.dropoffLabel}',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatDateTime(booking.ride.startTime),
            style: TextStyle(color: muted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Seats: ${booking.seatsBooked}',
                style: TextStyle(color: muted, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                '\$${booking.totalPrice.toStringAsFixed(0)}',
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IntentCard extends StatelessWidget {
  const _IntentCard({
    required this.intentId,
    required this.isDark,
    this.amount,
    this.currency,
  });

  final String intentId;
  final bool isDark;
  final int? amount;
  final String? currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2331) : const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF232836) : const Color(0xFFE6EAF2),
        ),
      ),
      child: Text(
        [
          'PaymentIntent: $intentId',
          if (amount != null)
            'Amount: ${amount!} ${currency == null ? '' : currency!.toUpperCase()}',
        ].join('\n'),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
        ),
      ),
    );
  }
}
