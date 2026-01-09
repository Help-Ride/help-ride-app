// book_ride_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';

import '../Models/ride_model.dart';
import '../widgets/passenger/ride_card.dart';
import 'book_ride_detail_screen.dart';

// Import your model and details screen
// import 'ride.dart';
// import 'book_ride_details_screen.dart';

class BookRidesScreen extends StatefulWidget {
  const BookRidesScreen({Key? key}) : super(key: key);

  @override
  State<BookRidesScreen> createState() => _BookRideScreenState();
}

class _BookRideScreenState extends State<BookRidesScreen> {
  final List<Ride> rides = [
    Ride(
      driverName: 'Sarah Johnson',
      driverInitials: 'SJ',
      rating: 4.9,
      totalRides: 127,
      departureTime: 'Today, 2:30 PM',
      duration: 45,
      availableSeats: 2,
      pricePerSeat: 25,
      isVerified: true,
      vehicleModel: 'Toyota Camry',
      vehicleYear: 2022,
      vehicleColor: 'Silver',
      licensePlate: 'ABC 1234',
      amenities: ['AC', 'Music', 'Pet-friendly'],
      pickupInstructions: 'Will wait near the main entrance',
      pickupLocation: 'Downtown Toronto',
      pickupSubtitle: 'Union Station',
      destinationLocation: 'Pearson Airport',
      destinationSubtitle: 'Terminal 1',
    ),
    Ride(
      driverName: 'Mike Chen',
      driverInitials: 'MC',
      rating: 4.8,
      totalRides: 93,
      departureTime: 'Today, 3:00 PM',
      duration: 50,
      availableSeats: 3,
      pricePerSeat: 22,
      isVerified: true,
    ),
    Ride(
      driverName: 'Mike Chen',
      driverInitials: 'MC',
      rating: 4.8,
      totalRides: 93,
      departureTime: 'Today, 3:00 PM',
      duration: 50,
      availableSeats: 3,
      pricePerSeat: 22,
      isVerified: true,
    ),
  ];

  final Map<int, int> selectedSeats = {};

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < rides.length; i++) {
      selectedSeats[i] = 1;
    }
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
          children: const [
            Text(
              'Available Rides',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Downtown Toronto → Pearson Airport',
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
            child: const Text(
              '3 rides found • Sorted by departure time',
              style: TextStyle(color: Colors.black87, fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: rides.length,
              itemBuilder: (context, index) {
                return RideCard(
                  ride: rides[index],
                  selectedSeats: selectedSeats[index]!,
                  onSeatsChanged: (seats) {
                    setState(() {
                      selectedSeats[index] = seats;
                    });
                  },
                  onDetailsPressed: () {
                    Get.to(BookRideDetailScreen(ride: rides[index]));
                  },
                  onBookPressed: () {
                    // Handle booking
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Booking ${selectedSeats[index]} seat(s)',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
