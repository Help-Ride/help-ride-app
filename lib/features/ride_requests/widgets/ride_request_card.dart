import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../bookings/utils/booking_formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/services/api_client.dart';
import '../models/ride_request.dart';
import '../models/ride_request_offer.dart';
import '../services/ride_requests_api.dart';

class RideRequestCard extends StatelessWidget {
  const RideRequestCard({
    super.key,
    required this.request,
    required this.onEdit,
    required this.onCancel,
    required this.canceling,
  });

  final RideRequest request;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final bool canceling;

  bool get _isCanceled {
    final s = request.status.toLowerCase();
    return s.contains('cancel') || s.contains('deleted');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final status = request.status.toLowerCase();

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
                formatDateTime(request.preferredDate),
                style: TextStyle(color: muted, fontSize: 12),
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
                  '${request.fromCity}  →  ${request.toCity}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: muted),
              const SizedBox(width: 6),
              Text(
                request.preferredTime,
                style: TextStyle(color: muted),
              ),
              if (request.arrivalTime != null &&
                  request.arrivalTime!.trim().isNotEmpty) ...[
                const SizedBox(width: 10),
                Icon(Icons.timer_outlined, size: 16, color: muted),
                const SizedBox(width: 6),
                Text(
                  request.arrivalTime!,
                  style: TextStyle(color: muted),
                ),
              ],
              const Spacer(),
              Icon(Icons.event_seat_outlined, size: 16, color: muted),
              const SizedBox(width: 6),
              Text(
                '${request.seatsNeeded} seat${request.seatsNeeded == 1 ? '' : 's'}',
                style: TextStyle(color: muted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.loop_outlined, size: 16, color: muted),
              const SizedBox(width: 6),
              Text(
                _prettyEnum(request.rideType),
                style: TextStyle(color: muted),
              ),
              const SizedBox(width: 12),
              Icon(Icons.swap_horiz, size: 16, color: muted),
              const SizedBox(width: 6),
              Text(
                _prettyEnum(request.tripType),
                style: TextStyle(color: muted),
              ),
            ],
          ),
          if (!_isCanceled) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () => _openOffersSheet(context, request),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.local_offer_outlined, size: 18),
                label: const Text('View Offers'),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: canceling ? null : onEdit,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: canceling ? null : onCancel,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: Text(canceling ? 'Cancelling...' : 'Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _openOffersSheet(BuildContext context, RideRequest request) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  var loading = true;
  String? error;
  List<RideRequestOffer> offers = [];
  var sheetOpen = true;

  void safeSetState(StateSetter setState, VoidCallback fn) {
    if (!sheetOpen) return;
    setState(fn);
  }

  Future<void> loadOffers(StateSetter setState) async {
    safeSetState(setState, () {
      loading = true;
      error = null;
    });
    try {
      final client = await ApiClient.create();
      final api = RideRequestsApi(client);
      final list = await api.listOffers(request.id);
      safeSetState(setState, () {
        offers = list;
      });
    } catch (e) {
      safeSetState(setState, () => error = e.toString());
    } finally {
      safeSetState(setState, () => loading = false);
    }
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          if (loading && offers.isEmpty && error == null) {
            Future.microtask(() => loadOffers(setState));
          }

          return Container(
            padding: EdgeInsets.fromLTRB(
              18,
              18,
              18,
              18 + MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121826) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offers',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${request.fromCity} → ${request.toCity}',
                  style: TextStyle(
                    color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                  ),
                ),
                const SizedBox(height: 12),
                if (loading)
                  const Center(child: CircularProgressIndicator())
                else if (error != null)
                  Column(
                    children: [
                      Text(
                        error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => loadOffers(setState),
                        child: const Text('Retry'),
                      ),
                    ],
                  )
                else if (offers.isEmpty)
                  Text(
                    'No offers yet.',
                    style: TextStyle(
                      color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                    ),
                  )
                else
                  Column(
                            children: offers
                        .map((o) => _OfferTile(
                              offer: o,
                              onAccept: () =>
                                  _handleOfferAction(context, request, o, true, setState, loadOffers),
                              onReject: () =>
                                  _handleOfferAction(context, request, o, false, setState, loadOffers),
                            ))
                        .toList(),
                  ),
              ],
            ),
          );
        },
      );
    },
  ).whenComplete(() {
    sheetOpen = false;
  });
}

Future<void> _handleOfferAction(
  BuildContext context,
  RideRequest request,
  RideRequestOffer offer,
  bool accept,
  StateSetter setState,
  Future<void> Function(StateSetter) reload,
) async {
  final client = await ApiClient.create();
  final api = RideRequestsApi(client);
  try {
    if (accept) {
      await api.acceptOffer(rideRequestId: request.id, offerId: offer.id);
      Get.snackbar('Accepted', 'Offer accepted.');
    } else {
      await api.rejectOffer(rideRequestId: request.id, offerId: offer.id);
      Get.snackbar('Rejected', 'Offer rejected.');
    }
    await reload(setState);
  } catch (e) {
    Get.snackbar('Failed', e.toString());
  }
}

class _OfferTile extends StatelessWidget {
  const _OfferTile({
    required this.offer,
    required this.onAccept,
    required this.onReject,
  });

  final RideRequestOffer offer;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final ride = offer.ride;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2331) : const Color(0xFFF3F5F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _prettyStatus(offer.status),
            style: TextStyle(
              color: muted,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          if (ride != null)
            Text(
              '${ride.fromCity} → ${ride.toCity}',
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          if (ride != null) ...[
            const SizedBox(height: 6),
            Text(
              '${formatDateTime(ride.startTime)} • \$${ride.pricePerSeat.toStringAsFixed(0)}/seat',
              style: TextStyle(color: muted),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: AppColors.passengerPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _prettyStatus(String raw) {
  final v = raw.trim().toLowerCase();
  if (v.contains('accepted') || v.contains('confirm')) return 'Accepted';
  if (v.contains('rejected')) return 'Rejected';
  if (v.contains('cancel')) return 'Cancelled';
  return 'Pending';
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, text) = _style(status);
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

  (Color, Color, String) _style(String s) {
    if (s.contains('pending'))
      return (const Color(0xFFFFF2D6), const Color(0xFFB86B00), 'Pending');
    if (s.contains('matched') || s.contains('offered'))
      return (const Color(0xFFE7F8EF), const Color(0xFF179C5E), 'Matched');
    if (s.contains('cancel'))
      return (const Color(0xFFFFE2E2), const Color(0xFFD64545), 'Cancelled');
    return (const Color(0xFFEFF2F6), const Color(0xFF6B7280), 'Open');
  }
}

String _prettyEnum(String raw) {
  return raw
      .split('-')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
