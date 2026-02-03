import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/place_picker_field.dart';
import '../../driver/widgets/create_ride/chip.dart';
import '../../driver/widgets/create_ride/picker_tile.dart';
import '../../driver/widgets/create_ride/section_title.dart';
import '../../driver/widgets/create_ride/text_field.dart';
import '../controllers/ride_request_form_controller.dart';

class RideRequestFormView extends GetView<RideRequestFormController> {
  const RideRequestFormView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final primary = AppColors.passengerPrimary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: isDark ? AppColors.darkText : AppColors.lightText,
        title: Text(
          controller.isEditing ? 'Edit Ride Request' : 'Request a Ride',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
            children: [
              Text(
                controller.isEditing
                    ? 'Update your request details'
                    : 'Ask drivers to offer a ride',
                style: TextStyle(color: muted),
              ),
              const SizedBox(height: 18),

              const SectionTitle('ROUTE'),
              if (controller.isEditing) ...[
                _RouteSummary(
                  from: controller.fromCtrl.text,
                  to: controller.toCtrl.text,
                ),
              ] else ...[
                PlacePickerField(
                  label: 'Departure Location',
                  hintText: 'Where are you starting from?',
                  icon: Icons.place_outlined,
                  controller: controller.fromCtrl,
                  onPicked: controller.setPickupPlace,
                ),
                const SizedBox(height: 12),
                PlacePickerField(
                  label: 'Destination',
                  hintText: 'Where are you going?',
                  icon: Icons.place,
                  iconColor: primary,
                  controller: controller.toCtrl,
                  onPicked: controller.setDropoffPlace,
                ),
              ],

              const SizedBox(height: 18),
              const SectionTitle('SCHEDULE'),

              Row(
                children: [
                  Expanded(
                    child: PickerTile(
                      label: 'Date',
                      value: controller.date.value == null
                          ? ''
                          : _fmtDate(controller.date.value!),
                      icon: Icons.calendar_today_outlined,
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: now,
                          lastDate: now.add(const Duration(days: 365)),
                          initialDate: controller.date.value ?? now,
                        );
                        if (picked != null) controller.date.value = picked;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PickerTile(
                      label: 'Time',
                      value: controller.time.value == null
                          ? ''
                          : controller.time.value!.format(context),
                      icon: Icons.access_time,
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: controller.time.value ?? TimeOfDay.now(),
                        );
                        if (picked != null) controller.time.value = picked;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              PickerTile(
                label: 'Arrival Time (Optional)',
                value: controller.arrivalTime.value == null
                    ? ''
                    : controller.arrivalTime.value!.format(context),
                icon: Icons.timer_outlined,
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime:
                        controller.arrivalTime.value ?? TimeOfDay.now(),
                  );
                  if (picked != null) controller.arrivalTime.value = picked;
                },
              ),

              const SizedBox(height: 18),
              const SectionTitle('REQUEST DETAILS'),

              ExoTextField(
                label: 'Seats Needed',
                hint: 'e.g. 1',
                controller: controller.seatsCtrl,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.event_seat_outlined,
              ),
              const SizedBox(height: 12),

              if (!controller.isEditing) ...[
                Text(
                  'Ride Type',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() {
                  final active = controller.rideType.value;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      SelectChip(
                        text: 'One-time',
                        active: active == 'one-time',
                        activeColor: primary,
                        onTap: () => controller.rideType.value = 'one-time',
                      ),
                      SelectChip(
                        text: 'Recurring',
                        active: active == 'recurring',
                        activeColor: primary,
                        onTap: () => controller.rideType.value = 'recurring',
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 14),

                Text(
                  'Trip Type',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() {
                  final active = controller.tripType.value;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      SelectChip(
                        text: 'One-way',
                        active: active == 'one-way',
                        activeColor: primary,
                        onTap: () => controller.tripType.value = 'one-way',
                      ),
                      SelectChip(
                        text: 'Round trip',
                        active: active == 'round-trip',
                        activeColor: primary,
                        onTap: () => controller.tripType.value = 'round-trip',
                      ),
                    ],
                  );
                }),
              ],

              const SizedBox(height: 18),
              if (controller.error.value != null)
                Text(
                  controller.error.value!,
                  style: const TextStyle(color: AppColors.error),
                ),
            ],
          );
        }),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Obx(() {
          final radius = BorderRadius.circular(16);
          return Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: controller.loading.value
                        ? null
                        : () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: radius),
                      side: BorderSide(
                        color: primary.withOpacity(0.35),
                        width: 1.4,
                      ),
                      foregroundColor: primary,
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: controller.loading.value
                        ? null
                        : (controller.canSubmitFlag.value
                              ? controller.submit
                              : null),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: radius),
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE9EEF6),
                      disabledForegroundColor: const Color(0xFF9AA3B2),
                      elevation: 0,
                    ),
                    child: Text(
                      controller.isEditing ? 'Update Request' : 'Request Ride',
                      style: const TextStyle(fontWeight: FontWeight.w900),
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
}

class _RouteSummary extends StatelessWidget {
  const _RouteSummary({required this.from, required this.to});
  final String from;
  final String to;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2331) : const Color(0xFFF3F5F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.place_outlined,
            color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$from  →  $to',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
