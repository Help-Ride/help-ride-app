import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/confirm_booking_controller.dart';
import '../widgets/passenger/booking_detail.dart';

class BookingConfirmedScreen extends GetView<BookingConfirmedController> {
  const BookingConfirmedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // ✅ Success Icon
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFF00BFA5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 56),
              ),

              const SizedBox(height: 24),
              const Text(
                'Booking Confirmed!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 32),

              // ✅ Booking Details
              BookingDetailRow(
                icon: Icons.location_on_outlined,
                iconColor: const Color(0xFF00BFA5),
                label: 'Route',
                value: controller.route,
              ),
              const SizedBox(height: 16),
              BookingDetailRow(
                icon: Icons.access_time,
                iconColor: const Color(0xFF2196F3),
                label: 'Departure',
                value: controller.departureTime,
              ),
              const SizedBox(height: 16),
              BookingDetailRow(
                icon: Icons.attach_money,
                iconColor: const Color(0xFF9C27B0),
                label: 'Total Price',
                value: '\$${controller.totalPrice.toInt()}',
              ),

              const SizedBox(height: 20),

              // ✅ Booking Reference
              Text(
                controller.bookingReference,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 40),

              // ✅ Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.goToMyRides,
                  child: const Text('View My Rides'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: controller.backToHome,
                  child: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
