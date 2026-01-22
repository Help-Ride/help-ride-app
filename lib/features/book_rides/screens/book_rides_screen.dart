// book_ride_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

import '../../home/Models/passenger_search_ride_model.dart';
import '../Models/book_rides_data.dart';
import '../Models/ride_model.dart';
import '../controllers/book_rides_controller.dart';
import '../widgets/passenger/ride_card.dart';
import 'book_ride_detail_screen.dart';

// Import your model and details screen
// import 'ride.dart';
// import 'book_ride_details_screen.dart';

class BookRidesScreen extends StatefulWidget {
  final SearchParams? params;
  final List<PassengerSearchRidesModel>? rides;

  BookRidesScreen({Key? key, this.params, this.rides}) : super(key: key);

  @override
  State<BookRidesScreen> createState() => _BookRideScreenState();
}

class _BookRideScreenState extends State<BookRidesScreen> {
  final controller = Get.put(BookRidesController());

  @override
  void initState() {
    super.initState();
    controller.setRides(widget.rides); // ✅ THIS IS CORRECT
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Rides',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${widget.params?.fromCity} → ${widget.params?.toCity}',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Text(
              '${controller.availableRides.length} rides found • Sorted by departure time',
              style: TextStyle(color: Colors.black87, fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),

          // ✅ FIX IS HERE
          Expanded(
            child: Obx(() {
              if (controller.availableRides.isEmpty) {
                return const Center(child: Text('No rides available'));
              }

              print("rides length ${controller.availableRides.length}");

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.availableRides.length,
                itemBuilder: (context, index) {
                  final ride = controller.availableRides[index];

                  return RideCard(
                    ride: ride,
                    selectedSeats: controller.selectedSeats[index] ?? 1,
                    onSeatsChanged: (seats) {
                      controller.updateSeats(index, seats);
                    },
                    onDetailsPressed: () {
                      Get.to(BookRideDetailScreen(ride: ride));
                    },
                    onBookPressed: () {
                      Get.snackbar(
                        'Booking',
                        'Booking ${controller.selectedSeats[index]} seat(s)',
                      );
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
