import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../bookings/utils/booking_formatters.dart';
import '../../ride_requests/models/ride_request.dart';
import '../../../shared/utils/input_validators.dart';
import '../controllers/driver_ride_requests_controller.dart';
import '../widgets/requests/driver_ride_request_card.dart';
import '../widgets/requests/driver_offer_card.dart';
import '../../../shared/widgets/place_picker_field.dart';

class DriverRideRequestsView extends GetView<DriverRideRequestsController> {
  const DriverRideRequestsView({super.key});

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
          'Ride Requests',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          child: Column(
            children: [
              Obx(
                () => _Tabs(
                  active: controller.tab.value,
                  onChange: controller.setTab,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Obx(() {
                  return controller.tab.value == DriverRideRequestsTab.requests
                      ? _RequestsTab(controller: controller)
                      : _OffersTab(controller: controller);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.active, required this.onChange});
  final DriverRideRequestsTab active;
  final ValueChanged<DriverRideRequestsTab> onChange;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2331) : const Color(0xFFEFF2F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF232836) : const Color(0xFFE3E8F2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabPill(
              text: 'Requests',
              active: active == DriverRideRequestsTab.requests,
              onTap: () => onChange(DriverRideRequestsTab.requests),
              isDark: isDark,
            ),
          ),
          Expanded(
            child: _TabPill(
              text: 'My Offers',
              active: active == DriverRideRequestsTab.offers,
              onTap: () => onChange(DriverRideRequestsTab.offers),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.text,
    required this.active,
    required this.onTap,
    required this.isDark,
  });

  final String text;
  final bool active;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? (isDark ? const Color(0xFF111827) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: active
              ? [
                  BoxShadow(
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                    color: isDark
                        ? Colors.black.withOpacity(0.4)
                        : const Color(0x12000000),
                  ),
                ]
              : const [],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: active
                ? (isDark ? AppColors.darkText : AppColors.lightText)
                : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
          ),
        ),
      ),
    );
  }
}

class _RequestsTab extends StatefulWidget {
  const _RequestsTab({required this.controller});
  final DriverRideRequestsController controller;

  @override
  State<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<_RequestsTab> {
  String? _autoOpeningRequestId;

  DriverRideRequestsController get controller => widget.controller;

  void _maybeAutoOpenNotificationRequest(BuildContext context) {
    if (_autoOpeningRequestId != null) return;
    final request = controller.pendingAutoOpenRequest();
    if (request == null) return;

    _autoOpeningRequestId = request.id;
    controller.markAutoOpenRequestHandled();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await _openOfferSheet(context, controller, request);
      } finally {
        if (mounted) {
          setState(() => _autoOpeningRequestId = null);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final header = Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF232836) : const Color(0xFFE6EAF2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Nearby filters',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => controller.refreshRequests(force: true),
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 40,
                      height: 40,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Obx(() {
                return Wrap(
                  spacing: 8,
                  children: DriverRideRequestsController.radiusOptionsKm.map((
                    km,
                  ) {
                    final active = controller.radiusKm.value == km;
                    return ChoiceChip(
                      label: Text('${km.toInt()} km'),
                      selected: active,
                      onSelected: (_) => controller.setRadiusKm(km),
                      selectedColor: AppColors.driverPrimary,
                      labelStyle: TextStyle(
                        color: active ? Colors.white : null,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  }).toList(),
                );
              }),
              const SizedBox(height: 8),
              Obx(() {
                return Row(
                  children: [
                    Text(
                      'Driver online',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkMuted
                            : AppColors.lightMuted,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: controller.driverOnline.value,
                      onChanged: controller.setDriverOnline,
                      activeThumbColor: AppColors.driverPrimary,
                    ),
                  ],
                );
              }),
              const SizedBox(height: 8),
              Obx(() {
                final canSort = controller.locationReady;
                return Row(
                  children: [
                    Text(
                      'Sort by distance',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkMuted
                            : AppColors.lightMuted,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: controller.sortByDistance.value,
                      onChanged: canSort
                          ? (v) => controller.sortByDistance.value = v
                          : null,
                      activeThumbColor: AppColors.driverPrimary,
                    ),
                  ],
                );
              }),
              const Divider(height: 18),
              Obx(() {
                final loading = controller.locationLoading.value;
                final error = controller.locationError.value;
                final serviceEnabled = controller.locationServiceEnabled.value;
                final denied = controller.permissionDenied;
                final deniedForever = controller.permissionDeniedForever;
                final position = controller.currentPosition.value;

                String title = 'Location';
                String message = '';
                VoidCallback? action;
                String? actionText;

                if (loading) {
                  message = 'Checking location...';
                } else if (error != null && error.isNotEmpty) {
                  message = 'Location error: $error';
                  action = () => controller.refreshNearbyRequests(force: true);
                  actionText = 'Retry';
                } else if (!serviceEnabled) {
                  message = 'Location services are disabled.';
                  action = controller.openLocationSettings;
                  actionText = 'Enable';
                } else if (deniedForever) {
                  message = 'Location permission is permanently denied.';
                  action = controller.openAppSettings;
                  actionText = 'Open Settings';
                } else if (denied) {
                  message = 'Location permission is denied.';
                  action = controller.requestLocationPermission;
                  actionText = 'Allow';
                } else if (position == null) {
                  message = 'Unable to fetch current location.';
                  action = () => controller.refreshNearbyRequests(force: true);
                  actionText = 'Retry';
                } else {
                  final accuracy = position.accuracy;
                  final timestamp = position.timestamp;
                  title = 'Current location';
                  message =
                      'Lat ${position.latitude.toStringAsFixed(5)}, '
                      'Lng ${position.longitude.toStringAsFixed(5)}';
                  if (accuracy > 0) {
                    message += ' · ±${accuracy.toStringAsFixed(0)}m';
                  }
                  message += ' · ${formatDateTime(timestamp.toLocal())}';
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.my_location,
                      color: isDark
                          ? AppColors.darkMuted
                          : AppColors.lightMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.darkText
                                  : AppColors.lightText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkMuted
                                  : AppColors.lightMuted,
                            ),
                          ),
                          if (action != null && actionText != null) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 34,
                              child: OutlinedButton(
                                onPressed: action,
                                child: Text(actionText),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (loading) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ],
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF232836) : const Color(0xFFE6EAF2),
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 2,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              leading: Icon(
                Icons.alt_route,
                color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
              ),
              title: Text(
                'Search by route',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              subtitle: Text(
                'Use a specific pickup and drop-off',
                style: TextStyle(
                  color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                ),
              ),
              children: [
                PlacePickerField(
                  label: 'From City',
                  hintText: 'e.g. Waterloo',
                  icon: Icons.place_outlined,
                  controller: controller.fromCtrl,
                  onPicked: (p) => controller.fromPick.value = p,
                ),
                const SizedBox(height: 12),
                PlacePickerField(
                  label: 'To City',
                  hintText: 'e.g. Toronto',
                  icon: Icons.place,
                  controller: controller.toCtrl,
                  onPicked: (p) => controller.toPick.value = p,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: controller.searchRequests,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.driverPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Search Requests',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );

    return Obx(() {
      final err = controller.requestsError.value;
      final list = controller.requests.toList();
      if (controller.sortByDistance.value && controller.locationReady) {
        list.sort((a, b) {
          final da = controller.distanceKmFor(a) ?? double.infinity;
          final db = controller.distanceKmFor(b) ?? double.infinity;
          return da.compareTo(db);
        });
      }

      final initialLoading = controller.requestsLoading.value && list.isEmpty;

      if (!initialLoading && err == null && list.isNotEmpty) {
        _maybeAutoOpenNotificationRequest(context);
      }

      Widget body;
      if (initialLoading) {
        body = const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        );
      } else if (err != null) {
        body = SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(err, style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => controller.refreshRequests(force: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      } else if (list.isEmpty) {
        body = SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              'No ride requests yet.',
              style: TextStyle(
                color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
              ),
            ),
          ),
        );
      } else {
        body = SliverPadding(
          padding: const EdgeInsets.only(bottom: 18),
          sliver: SliverList.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (_, i) {
              final r = list[i];
              return DriverRideRequestCard(
                request: r,
                onOffer: () => _openOfferSheet(context, controller, r),
              );
            },
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => controller.refreshRequests(force: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: header),
            body,
          ],
        ),
      );
    });
  }
}

class _OffersTab extends StatelessWidget {
  const _OffersTab({required this.controller});
  final DriverRideRequestsController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Obx(() {
      if (controller.offersLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      final err = controller.offersError.value;
      if (err != null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(err, style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: controller.fetchOffers,
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }

      final list = controller.offers;
      if (list.isEmpty) {
        return Center(
          child: Text(
            'No offers yet.',
            style: TextStyle(
              color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
            ),
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.only(bottom: 18),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, i) {
          final o = list[i];
          final canceling = controller.cancelingOfferIds.contains(o.id);
          return DriverOfferCard(
            offer: o,
            canceling: canceling,
            onCancel: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Cancel offer?'),
                  content: const Text('This offer will be withdrawn.'),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(result: false),
                      child: const Text('Keep'),
                    ),
                    TextButton(
                      onPressed: () => Get.back(result: true),
                      child: const Text('Cancel Offer'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await controller.cancelOffer(
                  rideRequestId: o.rideRequestId,
                  offerId: o.id,
                );
              }
            },
          );
        },
      );
    });
  }
}

Future<void> _openOfferSheet(
  BuildContext context,
  DriverRideRequestsController controller,
  RideRequest request,
) async {
  await controller.loadDriverRides();
  if (!context.mounted) return;
  final matches = controller.matchingRidesFor(request);
  if (matches.isEmpty) {
    await _openQuickCreateOfferSheet(context, controller, request);
    return;
  }

  final isDark = Theme.of(context).brightness == Brightness.dark;
  final rides = matches;
  String selectedRideId = rides.first.id;
  int seatsOffered = request.seatsNeeded;
  String? error;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final ride = rides.firstWhere(
            (r) => r.id == selectedRideId,
            orElse: () => rides.first,
          );
          final maxSeats = ride.seatsAvailable <= 0 ? 1 : ride.seatsAvailable;
          final minSeats = request.seatsNeeded;
          if (seatsOffered > maxSeats) {
            seatsOffered = maxSeats;
          }
          if (seatsOffered < minSeats) {
            seatsOffered = minSeats;
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
                  'Create Offer',
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
                Text(
                  'Select Ride',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 8),
                InputDecorator(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1C2331)
                        : const Color(0xFFF3F5F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedRideId,
                      isExpanded: true,
                      itemHeight: null,
                      items: rides.map((r) {
                        return DropdownMenuItem(
                          value: r.id,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              '${r.from} → ${r.to} (${formatDateTime(r.startTime)})',
                              maxLines: 2,
                              softWrap: true,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => selectedRideId = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Seats Offered (min $minSeats, max $maxSeats)',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: seatsOffered <= minSeats
                          ? null
                          : () => setState(() => seatsOffered -= 1),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      seatsOffered.toString(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.darkText
                            : AppColors.lightText,
                      ),
                    ),
                    IconButton(
                      onPressed: seatsOffered >= maxSeats
                          ? null
                          : () => setState(() => seatsOffered += 1),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(color: AppColors.error)),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (selectedRideId.isEmpty) {
                        setState(() => error = 'Select a ride.');
                        return;
                      }
                      if (seatsOffered < minSeats) {
                        setState(
                          () => error = 'Offer at least $minSeats seat(s).',
                        );
                        return;
                      }
                      try {
                        await controller.createOffer(
                          rideRequestId: request.id,
                          rideId: selectedRideId,
                          seatsOffered: seatsOffered,
                        );
                        Get.back();
                        Get.snackbar('Offer sent', 'Offer submitted.');
                      } catch (e) {
                        setState(() => error = e.toString());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.driverPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Send Offer',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<void> _openQuickCreateOfferSheet(
  BuildContext context,
  DriverRideRequestsController controller,
  RideRequest request,
) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final surfaceAlt = isDark ? const Color(0xFF1C2331) : const Color(0xFFF3F5F8);
  final requestTime = (request.preferredTime ?? '').trim().isNotEmpty
      ? request.preferredTime!.trim()
      : formatDateTime(request.preferredDate);
  final seatsCtrl = TextEditingController(text: request.seatsNeeded.toString());
  final priceCtrl = TextEditingController(
    text: _formatPriceSeed(request.quotedPricePerSeat ?? 25.0),
  );
  var submitting = false;
  String? error;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> submit() async {
            final seatsError = InputValidators.positiveInt(
              seatsCtrl.text,
              fieldLabel: 'Available seats',
              min: request.seatsNeeded,
            );
            if (seatsError != null) {
              setState(() => error = seatsError);
              return;
            }

            final priceError = InputValidators.nonNegativeDecimal(
              priceCtrl.text,
              fieldLabel: 'Price per seat',
            );
            if (priceError != null) {
              setState(() => error = priceError);
              return;
            }

            final seatsTotal = int.parse(seatsCtrl.text.trim());
            final pricePerSeat = double.parse(priceCtrl.text.trim());
            setState(() {
              submitting = true;
              error = null;
            });

            try {
              final finalPrice = await controller.createRideAndOffer(
                request: request,
                seatsTotal: seatsTotal,
                pricePerSeat: pricePerSeat,
              );
              Get.back();
              final adjusted =
                  finalPrice != null &&
                  (finalPrice - pricePerSeat).abs() > 0.009;
              final message = adjusted
                  ? 'Ride created and offer sent at \$${_formatPriceSeed(finalPrice)}/seat.'
                  : 'Ride created and offer sent.';
              Get.snackbar('Offer sent', message);
            } catch (e) {
              setState(() {
                submitting = false;
                error = e.toString();
              });
            }
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0x24FFFFFF)
                            : const Color(0xFFD6DCE8),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'No Scheduled Ride',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You don't have a scheduled ride for this request.",
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark
                          ? AppColors.darkMuted
                          : AppColors.lightMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Want to create one and send the offer automatically?',
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark
                          ? AppColors.darkMuted
                          : AppColors.lightMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: surfaceAlt,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.alt_route_rounded,
                              size: 18,
                              color: isDark
                                  ? AppColors.darkMuted
                                  : AppColors.lightMuted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${request.fromCity} → ${request.toCity}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? AppColors.darkText
                                      : AppColors.lightText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _QuickInfoChip(
                              icon: Icons.access_time_rounded,
                              text: requestTime,
                              isDark: isDark,
                            ),
                            _QuickInfoChip(
                              icon: Icons.event_seat_outlined,
                              text:
                                  '${request.seatsNeeded} seat${request.seatsNeeded == 1 ? '' : 's'} requested',
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _FieldHeader(
                    title: 'Available Seats',
                    helper:
                        'Set how many seats this new ride will publish. Minimum ${request.seatsNeeded}.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: seatsCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Enter seat count',
                      prefixIcon: const Icon(Icons.event_seat_outlined),
                      filled: true,
                      fillColor: surfaceAlt,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _FieldHeader(
                    title: 'Price Per Seat',
                    helper:
                        'This is the per-seat price the passenger will see on the offer.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Enter price',
                      prefixText: '\$ ',
                      filled: true,
                      fillColor: surfaceAlt,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE8E8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: submitting ? null : () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Not Now',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed: submitting ? null : submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.driverPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              submitting
                                  ? 'Creating...'
                                  : 'Create Ride & Send Offer',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  ).whenComplete(() {
    seatsCtrl.dispose();
    priceCtrl.dispose();
  });
}

String _formatPriceSeed(double value) {
  final fixed = value.toStringAsFixed(2);
  if (fixed.endsWith('.00')) return value.toStringAsFixed(0);
  if (fixed.endsWith('0')) return fixed.substring(0, fixed.length - 1);
  return fixed;
}

class _FieldHeader extends StatelessWidget {
  const _FieldHeader({
    required this.title,
    required this.helper,
    required this.isDark,
  });

  final String title;
  final String helper;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          helper,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
          ),
        ),
      ],
    );
  }
}

class _QuickInfoChip extends StatelessWidget {
  const _QuickInfoChip({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  final IconData icon;
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121826) : Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
        ],
      ),
    );
  }
}
