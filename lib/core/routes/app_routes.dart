import 'package:get/get.dart';
import 'package:help_ride/shared/bindings/shell_binding.dart';
import 'package:help_ride/shared/views/app_shell.dart';
import '../../features/auth/routes/auth_routes.dart';
import '../../features/book_rides/bindings/book_ride_detail_binding.dart';
import '../../features/book_rides/bindings/book_rides_binding.dart';
import '../../features/book_rides/bindings/confirm_booking_binding.dart';
import '../../features/book_rides/screens/book_ride_detail_screen.dart';
import '../../features/book_rides/screens/book_rides_screen.dart';
import '../../features/book_rides/screens/confirm_booking_screen.dart';
import '../../features/home/views/home_view.dart';
import '../../shared/views/splash_gate.dart';

class AppRoutes {
  static const gate = '/';
  static const shell = '/shell';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';

  //  Book Rides
  static const bookRides = '/book-rides';
  static const bookRideDetail = '/book-ride-detail';

  // Booking Confirmed
  static const bookingConfirmed = '/booking-confirmed';

  static final pages = [
    GetPage(name: gate, page: () => const SplashGate()),
    ...AuthRoutes.pages, // /login etc.
    GetPage(name: shell, page: () => const AppShell(), binding: ShellBinding()),
    GetPage(
      name:home,
      page: () => const HomeView(),
      binding: ShellBinding(), // 🔥 MUST be here
    ),

    GetPage(
      name: bookRides,
      page: () =>  BookRidesScreen(),
      binding: BookRidesBinding(),
    ),
    GetPage(
      name: bookRideDetail,
      page: () => const BookRideDetailScreen(),
      binding: BookRideDetailBinding(),
    ),
    GetPage(
      name: bookingConfirmed,
      page: () => const BookingConfirmedScreen(),
      binding: BookingConfirmedBinding(),
    ),
  ];
}
