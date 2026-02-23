import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../bookings/utils/booking_formatters.dart';
import '../../ride_requests/models/ride_request.dart';
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

class _RequestsTab extends StatelessWidget {
  const _RequestsTab({required this.controller});
  final DriverRideRequestsController controller;

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
    final goCreate = await showAdaptiveDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog.adaptive(
        title: const Text('No matching rides'),
        content: const Text(
          'Create a ride that matches this request before sending an offer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Create Ride'),
          ),
        ],
      ),
    );
    if (goCreate == true) {
      Get.toNamed(
        '/driver/create-ride',
        arguments: {
          'fromCity': request.fromCity,
          'toCity': request.toCity,
          if (request.fromLat != null) 'fromLat': request.fromLat,
          if (request.fromLng != null) 'fromLng': request.fromLng,
          if (request.toLat != null) 'toLat': request.toLat,
          if (request.toLng != null) 'toLng': request.toLng,
        },
      );
    }
    return;
  }

  final isDark = Theme.of(context).brightness == Brightness.dark;
  final rides = matches;
  String selectedRideId = rides.first.id;
  int seatsOffered = 1;
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
          if (seatsOffered > maxSeats) {
            seatsOffered = maxSeats;
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
                      items: rides.map((r) {
                        return DropdownMenuItem(
                          value: r.id,
                          child: Text(
                            '${r.from} → ${r.to} (${formatDateTime(r.startTime)})',
                            overflow: TextOverflow.ellipsis,
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
                  'Seats Offered (max $maxSeats)',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: seatsOffered <= 1
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
                      if (seatsOffered <= 0) {
                        setState(() => error = 'Pick seats offered.');
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
