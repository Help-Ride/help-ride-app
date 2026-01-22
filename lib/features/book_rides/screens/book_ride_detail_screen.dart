import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';

import '../../../core/routes/app_routes.dart';
import '../Models/passenger_ride_request_model.dart';
import '../Models/ride_model.dart';
import '../bottom_sheets/confirm_booking_bottomsheet.dart';
import '../controllers/book_ride_detail_controller.dart';
import '../widgets/passenger/detail_card.dart';
import '../widgets/passenger/trip_location.dart';

class BookRideDetailScreen extends StatefulWidget {
  final Ride? ride;

  const BookRideDetailScreen({Key? key, this.ride}) : super(key: key);

  @override
  State<BookRideDetailScreen> createState() => _BookRideDetailScreenState();
}

class _BookRideDetailScreenState extends State<BookRideDetailScreen> {
  int selectedSeats = 1;

  @override
  Widget build(BuildContext context) {
    final totalPrice = widget.ride!.pricePerSeat * selectedSeats;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ride Details',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Driver Card
                  DetailCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8E8E8),
                                borderRadius: BorderRadius.circular(32),
                              ),
                              child: Center(
                                child: Text(
                                  widget.ride!.driverInitials,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        widget.ride!.driverName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                      ),
                                      if (widget.ride!.isVerified) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE3F2FD),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(
                                                Icons.verified,
                                                size: 12,
                                                color: Color(0xFF1976D2),
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Verified',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF1976D2),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Color(0xFFFFA000),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.ride!.rating.toString(),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        '•',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '${widget.ride!.totalRides} rides',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        '•',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Since\n2023',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // Handle call
                                },
                                icon: const Icon(
                                  Icons.phone_outlined,
                                  size: 18,
                                ),
                                label: const Text('Call'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.black87,
                                  side: const BorderSide(
                                    color: Color(0xFFE0E0E0),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // Handle message
                                },
                                icon: const Icon(
                                  Icons.message_outlined,
                                  size: 18,
                                ),
                                label: const Text('Message'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.black87,
                                  side: const BorderSide(
                                    color: Color(0xFFE0E0E0),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Vehicle Information
                  if (widget.ride!.vehicleModel != null)
                    DetailCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.directions_car_outlined, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Vehicle Information',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Vehicle',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${widget.ride!.vehicleModel} ${widget.ride!.vehicleYear}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Color',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  widget.ride!.vehicleColor ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'License Plate',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  widget.ride!.licensePlate ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  // Trip Details
                  DetailCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Trip Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TripLocation(
                          icon: Icons.circle,
                          iconColor: Colors.grey,
                          title: 'Pickup',
                          location:
                              widget.ride!.pickupLocation ?? 'Downtown Toronto',
                          subtitle:
                              widget.ride!.destinationLocation ?? 'Union Station',
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 2,
                          height: 24,
                          color: const Color(0xFFE0E0E0),
                        ),
                        TripLocation(
                          icon: Icons.circle,
                          iconColor: const Color(0xFF00BFA5),
                          title: 'Destination',
                          location:
                              widget.ride!.destinationLocation ??
                              'Pearson Airport',
                          subtitle:
                              widget.ride!.destinationSubtitle ?? 'Terminal 1',
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Date & Time',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.ride!.departureTime,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Duration',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${widget.ride!.duration} min (32 km)',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Amenities
                  if (widget.ride!.amenities != null &&
                      widget.ride!.amenities!.isNotEmpty)
                    DetailCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Amenities',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: widget.ride!.amenities!
                                .map(
                                  (amenity) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F5F5),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      amenity,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  // Pickup Instructions
                  if (widget.ride!.pickupInstructions != null)
                    DetailCard(
                      color: const Color(0xFFF0F9FF),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pickup Instructions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.ride!.pickupInstructions!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  // Select Seats
                  DetailCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Select Seats',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              '${widget.ride!.availableSeats} available',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: List.generate(3, (index) {
                            final seatNumber = index + 1;
                            final isSelected = selectedSeats == seatNumber;
                            final isDisabled =
                                seatNumber > widget.ride!.availableSeats;

                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: index < 2 ? 8 : 0,
                                ),
                                child: GestureDetector(
                                  onTap: isDisabled
                                      ? null
                                      : () {
                                          setState(() {
                                            selectedSeats = seatNumber;
                                          });
                                        },
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFE0F2F1)
                                          : Colors.white,
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF00BFA5)
                                            : isDisabled
                                            ? const Color(0xFFE0E0E0)
                                            : const Color(0xFFBDBDBD),
                                        width: isSelected ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        seatNumber == 1
                                            ? '1 seat'
                                            : seatNumber == 2
                                            ? '2 seats'
                                            : '3 seats',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: isDisabled
                                              ? const Color(0xFFBDBDBD)
                                              : isSelected
                                              ? const Color(0xFF00BFA5)
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          // Bottom Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Total Price',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${totalPrice.toInt()}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        '\$${widget.ride!.pricePerSeat.toInt()} × $selectedSeats seat',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      ConfirmBookingBottomSheet.show(
                        context: context,
                        ride: widget.ride!,
                        selectedSeats: selectedSeats,
                        onConfirm: () {
                          final controller = Get.put(BookRideDetailController());

                          // final controller = Get.find<BookRideDetailController>();

                          final request = PassengerRideRequestModel(
                            fromCity: 'Waterloo',
                            fromLat: 43.4643,
                            fromLng: -80.5204,
                            toCity: 'Toronto',
                            toLat: 43.6532,
                            toLng: -79.3832,
                            preferredDate: '2025-12-20T08:00:00.000Z',
                            seatsNeeded: selectedSeats,
                            rideType: 'one-time',
                            tripType: 'one-way',
                          );



                          controller.requestRide(
                            request: request,
                            onSuccess: () {
                              Get.offNamed(AppRoutes.bookingConfirmed);
                            },
                          );
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BFA5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Request Ride',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
