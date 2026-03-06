import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../widgets/my_rides/driver_ride_bookings_sheet.dart';

class DriverRideDetailsView extends StatefulWidget {
  const DriverRideDetailsView({super.key});

  @override
  State<DriverRideDetailsView> createState() => _DriverRideDetailsViewState();
}

class _DriverRideDetailsViewState extends State<DriverRideDetailsView> {
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openSheet());
  }

  String get _rideId {
    final args = Get.arguments;
    if (args is Map) {
      final fromArgs = (args['rideId'] ?? '').toString().trim();
      if (fromArgs.isNotEmpty) return fromArgs;
    }
    return (Get.parameters['id'] ?? '').toString().trim();
  }

  Future<void> _openSheet() async {
    if (_opened || !mounted) return;
    _opened = true;

    final rideId = _rideId;
    if (rideId.isEmpty) {
      Get.back();
      return;
    }

    await showDriverRideBookingsSheet(context, rideId: rideId);

    if (!mounted) return;
    Get.back();
  }

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
          'Ride Bookings',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: const SafeArea(child: Center(child: CircularProgressIndicator())),
    );
  }
}
