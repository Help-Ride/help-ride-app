import 'package:flutter_test/flutter_test.dart';
import 'package:help_ride/features/bookings/controllers/my_rides_controller.dart';
import 'package:help_ride/features/bookings/models/booking.dart';

void main() {
  test('accepted unpaid future booking exposes the pay action', () {
    final controller = MyRidesController();
    final booking = Booking(
      id: 'booking-1',
      rideId: 'ride-1',
      passengerId: 'passenger-1',
      seatsBooked: 1,
      status: 'ACCEPTED',
      paymentStatus: 'unpaid',
      createdAt: DateTime.now(),
      ride: BookingRide(
        id: 'ride-1',
        fromCity: 'Toronto',
        toCity: 'Ottawa',
        startTime: DateTime.now().add(const Duration(days: 1)),
        pricePerSeat: 25,
        driverId: 'driver-1',
        status: 'open',
      ),
    );

    expect(controller.paymentUiState(booking), BookingPaymentUiState.payNow);
    expect(controller.shouldShowPayAction(booking), isTrue);
  });
}
