import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:help_ride/features/rides/widgets/ride_details/ride_details_body.dart';
import 'package:help_ride/features/rides/widgets/ride_details/ride_details_bottom_bar.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/ride_details_controller.dart';

class RideDetailsView extends GetView<RideDetailsController> {
  const RideDetailsView({super.key});

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
          'Ride Details',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: const SafeArea(child: RideDetailsBody()),
      bottomNavigationBar: const RideDetailsBottomBar(),
    );
  }
}
