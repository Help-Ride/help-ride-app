import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/my_rides_controller.dart';

class BookingPaymentProcessingView extends StatelessWidget {
  const BookingPaymentProcessingView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = (Get.arguments as Map?) ?? {};
    final route = (args['route'] ?? '').toString();
    final paymentIntentId = (args['paymentIntentId'] ?? '').toString().trim();
    final pollFuture = _readPollFuture(args['pollFuture']);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
            child: FutureBuilder<PaymentPollResult>(
              future: pollFuture ?? Future.value(PaymentPollResult.failed),
              builder: (context, snapshot) {
                final waiting =
                    snapshot.connectionState != ConnectionState.done;
                final result = waiting
                    ? PaymentPollResult.pending
                    : snapshot.data ?? PaymentPollResult.failed;

                final title = _titleFor(waiting: waiting, result: result);
                final subtitle = _subtitleFor(waiting: waiting, result: result);
                final icon = _iconFor(waiting: waiting, result: result);
                final iconColor = _iconColorFor(
                  isDark: isDark,
                  waiting: waiting,
                  result: result,
                );

                return Column(
                  children: [
                    const Spacer(),
                    Container(
                      height: 88,
                      width: 88,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(
                          alpha: isDark ? 0.22 : 0.12,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: waiting
                          ? Center(
                              child: SizedBox(
                                height: 34,
                                width: 34,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: iconColor,
                                ),
                              ),
                            )
                          : Icon(icon, size: 42, color: iconColor),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: isDark
                            ? AppColors.darkText
                            : AppColors.lightText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkMuted
                            : AppColors.lightMuted,
                        height: 1.4,
                      ),
                    ),
                    if (route.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        route,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.darkText
                              : AppColors.lightText,
                        ),
                      ),
                    ],
                    if (paymentIntentId.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'PaymentIntent: $paymentIntentId',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkMuted
                              : AppColors.lightMuted,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (!waiting)
                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Get.back(result: result.name),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.passengerPrimary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            _buttonFor(result),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<PaymentPollResult>? _readPollFuture(dynamic raw) {
    if (raw is Future<PaymentPollResult>) return raw;
    if (raw is Future) {
      return raw.then((value) {
        if (value is PaymentPollResult) return value;
        if (value is String) return _resultFromString(value);
        return PaymentPollResult.pending;
      });
    }
    return null;
  }

  PaymentPollResult _resultFromString(String value) {
    switch (value) {
      case 'paid':
        return PaymentPollResult.paid;
      case 'refunded':
        return PaymentPollResult.refunded;
      case 'failed':
        return PaymentPollResult.failed;
      default:
        return PaymentPollResult.pending;
    }
  }

  String _titleFor({required bool waiting, required PaymentPollResult result}) {
    if (waiting) return 'Payment processing...';
    if (result == PaymentPollResult.paid) return 'Payment received';
    if (result == PaymentPollResult.refunded) return 'Payment refunded';
    if (result == PaymentPollResult.failed) return 'Payment failed';
    return 'Payment processing...';
  }

  String _subtitleFor({
    required bool waiting,
    required PaymentPollResult result,
  }) {
    if (waiting) {
      return 'Waiting for backend webhook confirmation.';
    }
    if (result == PaymentPollResult.paid) {
      return 'Your ride is marked as PAID.';
    }
    if (result == PaymentPollResult.refunded) {
      return 'This payment has been refunded.';
    }
    if (result == PaymentPollResult.failed) {
      return 'We could not confirm your payment.';
    }
    return 'Still waiting for webhook confirmation.';
  }

  IconData _iconFor({
    required bool waiting,
    required PaymentPollResult result,
  }) {
    if (waiting) return Icons.hourglass_top_rounded;
    if (result == PaymentPollResult.paid) return Icons.check_circle;
    if (result == PaymentPollResult.refunded) return Icons.undo_rounded;
    if (result == PaymentPollResult.failed) return Icons.error_rounded;
    return Icons.hourglass_top_rounded;
  }

  Color _iconColorFor({
    required bool isDark,
    required bool waiting,
    required PaymentPollResult result,
  }) {
    if (waiting) return AppColors.passengerPrimary;
    if (result == PaymentPollResult.paid) return const Color(0xFF179C5E);
    if (result == PaymentPollResult.refunded) return const Color(0xFF6B7280);
    if (result == PaymentPollResult.failed) return AppColors.error;
    return isDark ? AppColors.darkMuted : AppColors.lightMuted;
  }

  String _buttonFor(PaymentPollResult result) {
    if (result == PaymentPollResult.paid) return 'Done';
    if (result == PaymentPollResult.refunded) return 'Back';
    if (result == PaymentPollResult.failed) return 'Back';
    return 'Back to rides';
  }
}
