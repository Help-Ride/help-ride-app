import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:help_ride/features/chat/services/chat_api.dart';
import 'package:help_ride/features/chat/views/chat_thread_view.dart';
import 'package:help_ride/shared/controllers/session_controller.dart';
import 'package:help_ride/shared/services/api_client.dart';
import 'package:help_ride/shared/services/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/my_rides_controller.dart';
import '../routes/booking_routes.dart';
import '../utils/booking_formatters.dart';
import '../widgets/rides_tabs.dart';
import '../widgets/booking_card.dart';
import '../../ride_requests/widgets/ride_request_card.dart';

class MyRidesView extends GetView<MyRidesController> {
  const MyRidesView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: isDark ? AppColors.darkText : AppColors.lightText,
        title: const Text(
          'My Rides',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          child: Column(
            children: [
              Obx(
                () => RidesTabs(
                  active: controller.tab.value,
                  onChange: controller.setTab,
                ),
              ),
              const SizedBox(height: 14),

              Obx(() {
                if (controller.loading.value) {
                  return const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final err = controller.error.value;
                if (err != null) {
                  return Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            err,
                            style: const TextStyle(color: AppColors.error),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: controller.fetch,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final list = controller.filtered;
                if (controller.tab.value == MyRidesTab.requests) {
                  final requests = controller.filteredRequests;
                  return Expanded(
                    child: RefreshIndicator(
                      onRefresh: controller.fetch,
                      child: requests.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                const SizedBox(height: 120),
                                Center(
                                  child: Text(
                                    'No ride requests yet.',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.darkMuted
                                          : AppColors.lightMuted,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.only(bottom: 18),
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: requests.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (_, i) {
                                final r = requests[i];
                                final canceling = controller.cancelingRequestIds
                                    .contains(r.id);
                                return RideRequestCard(
                                  request: r,
                                  canceling: canceling,
                                  onEdit: () => Get.toNamed(
                                    '/ride-requests/edit',
                                    arguments: {'request': r},
                                  ),
                                  onCancel: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Cancel request?'),
                                        content: const Text(
                                          'This will remove your ride request.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Get.back(result: false),
                                            child: const Text('Keep'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Get.back(result: true),
                                            child: const Text('Cancel Request'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await controller.cancelRequest(r.id);
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  );
                }

                return Expanded(
                  child: RefreshIndicator(
                    onRefresh: controller.fetch,
                    child: list.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 120),
                              Center(
                                child: Text(
                                  'No rides yet.',
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.darkMuted
                                        : AppColors.lightMuted,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.only(bottom: 18),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: list.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 14),
                            itemBuilder: (_, i) {
                              final booking = list[i];
                              final canPay = controller.shouldShowPayAction(
                                booking,
                              );
                              final canCancel = controller.canCancelBooking(
                                booking,
                              );
                              final rideIdForChat =
                                  booking.rideId.trim().isNotEmpty
                                  ? booking.rideId.trim()
                                  : booking.ride.id.trim();
                              final canChat =
                                  isPaymentPaidStatus(booking.paymentStatus) &&
                                  _isConfirmedBookingStatus(booking.status) &&
                                  rideIdForChat.isNotEmpty;
                              return BookingCard(
                                b: booking,
                                showPay: canPay,
                                showCancel: canCancel,
                                showChat: canChat,
                                isPaying: controller.isPaying(booking.id),
                                isCanceling: controller.isCancelingBooking(
                                  booking.id,
                                ),
                                payButtonLabel: controller.payButtonLabel(
                                  booking,
                                ),
                                paymentStateLabel: controller.paymentStateLabel(
                                  booking,
                                ),
                                onDetails: booking.rideId.trim().isEmpty
                                    ? null
                                    : () => Get.toNamed(
                                        '/rides/${booking.rideId}',
                                        arguments: {
                                          'seats': booking.seatsBooked,
                                          'bookingId': booking.id,
                                          'bookingStatus': booking.status,
                                          'bookingPaymentStatus':
                                              booking.paymentStatus,
                                          'bookingPassengerId':
                                              booking.passengerId,
                                          'bookingPickupName':
                                              booking.passengerPickupName,
                                          'bookingPickupLat':
                                              booking.passengerPickupLat,
                                          'bookingPickupLng':
                                              booking.passengerPickupLng,
                                          'bookingDropoffName':
                                              booking.passengerDropoffName,
                                          'bookingDropoffLat':
                                              booking.passengerDropoffLat,
                                          'bookingDropoffLng':
                                              booking.passengerDropoffLng,
                                        },
                                      ),
                                onPay: canPay
                                    ? () => Get.toNamed(
                                        BookingRoutes.payNow,
                                        arguments: {'booking': booking},
                                      )
                                    : null,
                                onChat: canChat
                                    ? () async {
                                        final session =
                                            Get.isRegistered<SessionController>()
                                            ? Get.find<SessionController>()
                                            : null;
                                        final currentUserId =
                                            session?.user.value?.id ?? '';
                                        if (currentUserId.isEmpty) {
                                          Get.snackbar(
                                            'Chat',
                                            'Please sign in to chat.',
                                          );
                                          return;
                                        }

                                        final passengerId = booking.passengerId
                                            .trim()
                                            .isNotEmpty
                                            ? booking.passengerId.trim()
                                            : currentUserId;

                                        try {
                                          final client = await ApiClient.create();
                                          final api = ChatApi(client);
                                          final conversation =
                                              await api.createOrGetConversation(
                                                rideId: rideIdForChat,
                                                passengerId: passengerId,
                                                currentUserId: currentUserId,
                                                currentRole: session
                                                    ?.user
                                                    .value
                                                    ?.roleDefault,
                                              );
                                          Get.to(
                                            () => ChatThreadView(
                                              conversation: conversation,
                                            ),
                                          );
                                        } catch (e) {
                                          final message = e is ApiException
                                              ? e.message
                                              : 'Unable to open chat right now.';
                                          Get.snackbar(
                                            'Chat unavailable',
                                            message,
                                          );
                                        }
                                      }
                                    : null,
                                onCancel: canCancel
                                    ? () async {
                                        final confirm =
                                            await showDialog<bool>(
                                              context: context,
                                              builder: (_) => AlertDialog(
                                                title: const Text(
                                                  'Cancel booking?',
                                                ),
                                                content: const Text(
                                                  'This will cancel your booking for this ride.',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Get.back(result: false),
                                                    child: const Text('Keep'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Get.back(result: true),
                                                    child: const Text(
                                                      'Cancel Booking',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ) ??
                                            false;
                                        if (!confirm) return;
                                        await controller.cancelBooking(booking);
                                      }
                                    : null,
                              );
                            },
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
}

bool _isConfirmedBookingStatus(String value) {
  final status = value.toLowerCase().trim();
  return status.contains('confirm') || status.contains('accept');
}
