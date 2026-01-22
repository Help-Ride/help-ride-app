import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/create_ride_request_controller.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/date_time_selector.dart';
import '../widgets/info_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_label.dart';

class CreateRideRequestScreen extends GetView<CreateRideRequestController> {
  const CreateRideRequestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Ride Request',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Let drivers know you need a ride',
              style: TextStyle(
                color: Color(0xFF757575),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Route Details',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 20),

              SectionLabel(text: 'Pickup Location'),
              CustomTextField(
                controller: controller.pickupLocationController,
                hintText: 'Where are you starting from?',
                prefixIcon: Icons.location_on_outlined,
              ),
              SizedBox(height: 20),

              SectionLabel(text: 'Destination'),
              CustomTextField(
                controller: controller.destinationController,
                hintText: 'Where do you want to go?',
                prefixIcon: Icons.location_on,
                iconColor: Color(0xFF00BFA5),
              ),
              SizedBox(height: 24),

              SectionLabel(text: 'When do you need a ride?'),
              Row(
                children: [
                  // Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date',
                          style: TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Obx(
                              () => SizedBox(
                            height: 52,
                            width: double.infinity,
                            child: DateTimeSelector(
                              icon: Icons.calendar_today_outlined,
                              displayText: controller.formatDate(
                                controller.selectedDate.value,
                              ),
                              onTap: () => controller.selectDate(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),

                  // Time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Time',
                          style: TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Obx(
                              () => SizedBox(
                            height: 52,
                            width: double.infinity,
                            child: DateTimeSelector(
                              icon: Icons.access_time,
                              displayText: controller.formatTime(
                                controller.selectedTime.value,
                              ),
                              onTap: () => controller.selectTime(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 28),

              Text(
                'Preferences',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 20),

              SectionLabel(text: 'Number of Seats'),
              CustomTextField(
                controller: controller.numberOfSeatsController,
                hintText: '',
                prefixIcon: Icons.person_outline,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),

              SectionLabel(text: 'Maximum Price Per Seat (Optional)'),
              CustomTextField(
                controller: controller.maxPriceController,
                hintText: 'e.g., 50',
                prefixIcon: Icons.attach_money,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 20),

              SectionLabel(text: 'Additional Notes (Optional)'),
              CustomTextField(
                controller: controller.additionalNotesController,
                hintText: 'Any special requirements or additional information',
                prefixIcon: Icons.notes_outlined,
                maxLines: 4,
              ),
              SizedBox(height: 24),

              InfoCard(
                message:
                'Your ride request will be visible to drivers. They can offer you a ride if they\'re traveling on a similar route.',
              ),
              SizedBox(height: 24),

              Obx(
                    () => PrimaryButton(
                  text: 'Create Ride Request',
                  onPressed: controller.createRideRequest,
                  isLoading: controller.isLoading.value,
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
