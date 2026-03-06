import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../rides/utils/ride_recurrence.dart';
import '../../../shared/widgets/place_picker_field.dart';
import '../controllers/create_ride_controller.dart';
import '../widgets/create_ride/chip.dart';
import '../widgets/create_ride/info_box.dart';
import '../widgets/create_ride/picker_tile.dart';
import '../widgets/create_ride/ride_price_preview.dart';
import '../widgets/create_ride/section_title.dart';
import '../widgets/create_ride/text_area.dart';
import '../widgets/create_ride/text_field.dart';

class CreateRideView extends GetView<CreateRideController> {
  const CreateRideView({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.driverPrimary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: isDark ? AppColors.darkText : AppColors.lightText,
        title: const Text(
          'Create a Ride',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          return ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
            children: [
              Text(
                'Offer a ride to passengers',
                style: TextStyle(color: muted),
              ),
              const SizedBox(height: 18),

              const SectionTitle('ROUTE'),
              PlacePickerField(
                label: 'Departure Location',
                hintText: 'Where are you starting from?',
                icon: Icons.place_outlined,
                controller: controller.fromCtrl,
                onPicked: (p) => controller.fromPick.value = p,
                errorText: controller.fromError,
              ),
              const SizedBox(height: 12),
              PlacePickerField(
                label: 'Destination',
                hintText: 'Where are you going?',
                icon: Icons.place,
                iconColor: primary,
                controller: controller.toCtrl,
                onPicked: (p) => controller.toPick.value = p,
                errorText: controller.toError,
              ),
              const SizedBox(height: 12),
              ExoTextField(
                label: 'Stops (Optional)',
                hint: 'e.g., Downtown, Union Station',
                controller: controller.stopsCtrl,
              ),
              const SizedBox(height: 6),
              Text(
                'Separate multiple stops with commas',
                style: TextStyle(color: muted, fontSize: 12),
              ),

              const SizedBox(height: 18),
              const SectionTitle('SCHEDULE'),

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
                      onTap: () => controller.toggleRideType('one-time'),
                    ),
                    SelectChip(
                      text: 'Recurring',
                      active: active == 'recurring',
                      activeColor: primary,
                      onTap: () => controller.toggleRideType('recurring'),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 14),

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
                          initialDate: now,
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
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) controller.time.value = picked;
                      },
                    ),
                  ),
                ],
              ),
              if (controller.dateError != null || controller.timeError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    controller.dateError ?? controller.timeError!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              Obx(() {
                if (!controller.isRecurring) return const SizedBox.shrink();

                final occurrences = controller.recurringOccurrenceStarts;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),
                    Text(
                      'Repeat On',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.darkText
                            : AppColors.lightText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: rideRecurrenceDayOrder.map((day) {
                        return SelectChip(
                          text: rideRecurrenceDayLabels[day] ?? day,
                          active: controller.recurrenceDays[day] == true,
                          activeColor: primary,
                          onTap: () => controller.toggleRecurrenceDay(day),
                        );
                      }).toList(),
                    ),
                    if (controller.recurrenceDaysError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        controller.recurrenceDaysError!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ],
                    const SizedBox(height: 14),
                    PickerTile(
                      label: 'Repeat Until',
                      value: controller.recurrenceEndDate.value == null
                          ? ''
                          : _fmtDate(controller.recurrenceEndDate.value!),
                      icon: Icons.event_repeat_outlined,
                      onTap: () async {
                        final selectedStart =
                            controller.date.value ?? DateTime.now();
                        final initialDate =
                            controller.recurrenceEndDate.value ??
                            selectedStart.add(const Duration(days: 28));
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: selectedStart,
                          lastDate: selectedStart.add(
                            const Duration(days: 365),
                          ),
                          initialDate: initialDate,
                        );
                        if (picked != null) {
                          controller.recurrenceEndDate.value = picked;
                        }
                      },
                    ),
                    if (controller.recurrenceEndDateError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        controller.recurrenceEndDateError!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF111827)
                            : const Color(0xFFF5F8FC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF232836)
                              : const Color(0xFFDCE5F2),
                        ),
                      ),
                      child: Text(
                        occurrences.isEmpty
                            ? 'Choose repeat days and an end date to create a recurring schedule.'
                            : 'This will publish ${occurrences.length} rides on ${controller.recurrenceDaysLabel} through ${_fmtDate(controller.recurrenceEndDate.value!)}.',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkMuted
                              : AppColors.lightMuted,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                );
              }),

              const SizedBox(height: 18),
              const SectionTitle('CAPACITY & PRICING'),

              Row(
                children: [
                  Expanded(
                    child: ExoTextField(
                      label: 'Available Seats',
                      hint: 'e.g. 3',
                      controller: controller.seatsCtrl,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.event_seat_outlined,
                      onChanged: (_) {},
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      errorText: controller.seatsError,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ExoTextField(
                      label: 'Minimum Price / Seat',
                      hint: '0 = auto',
                      controller: controller.priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      prefixIcon: Icons.attach_money,
                      onChanged: (_) {},
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      errorText: controller.priceError,
                    ),
                  ),
                ],
              ),
              if (controller.pricingPreviewLoading.value &&
                  controller.pricingPreview.value == null) ...[
                const SizedBox(height: 10),
                const LinearProgressIndicator(minHeight: 2),
              ],
              if (controller.pricingPreview.value != null) ...[
                const SizedBox(height: 10),
                RidePricePreview(preview: controller.pricingPreview.value!),
              ],

              const SizedBox(height: 18),
              const SectionTitle('AMENITIES'),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: controller.amenities.keys.map((k) {
                  final active = controller.amenities[k] == true;
                  return SelectChip(
                    text: k,
                    active: active,
                    activeColor: primary,
                    onTap: () => controller.toggleAmenity(k),
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),
              ExoTextArea(
                label: 'Additional Notes (Optional)',
                hint:
                    'e.g., Pickup instructions, luggage space available, etc.',
                controller: controller.notesCtrl,
              ),

              const SizedBox(height: 18),
              const InfoBox(),
              const SizedBox(height: 10),

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
            child: SizedBox(
              height: 52,
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
                          color: AppColors.driverPrimary.withOpacity(0.35),
                          width: 1.4,
                        ),
                        foregroundColor: AppColors.driverPrimary,
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
                          : (controller.canPublish ? controller.publish : null),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: radius),
                        backgroundColor: AppColors.driverPrimary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFE9EEF6),
                        disabledForegroundColor: const Color(0xFF9AA3B2),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Publish Ride',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
