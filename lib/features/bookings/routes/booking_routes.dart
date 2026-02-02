import 'package:get/get.dart';
import 'package:help_ride/features/bookings/bindings/my_rides_binding.dart';
import 'package:help_ride/features/bookings/views/booking_success_view.dart';
import 'package:help_ride/features/bookings/views/my_rides_view.dart';
import 'package:help_ride/features/bookings/views/pay_now_view.dart';
import 'package:help_ride/features/bookings/views/payment_processing_view.dart';

class BookingRoutes {
  static const success = '/booking/success';
  static const payNow = '/booking/pay';
  static const paymentProcessing = '/booking/payment-processing';

  static final pages = [
    // wherever your GetPages are (AppRoutes or feature routes)
    GetPage(name: success, page: () => const BookingSuccessView()),
    GetPage(
      name: payNow,
      page: () => const BookingPayNowView(),
      binding: MyRidesBinding(),
    ),
    GetPage(
      name: paymentProcessing,
      page: () => const BookingPaymentProcessingView(),
      binding: MyRidesBinding(),
    ),
    GetPage(
      name: '/my-rides',
      page: () => const MyRidesView(),
      binding: MyRidesBinding(),
    ),
    // GetPage(name: '/booking/success', page: () => const BookingSuccessView()),
  ];
}
