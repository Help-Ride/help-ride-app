import 'package:get/get.dart';

enum HomeRole { passenger, driver }

class HomeController extends GetxController {
  final role = HomeRole.passenger.obs;

  void setRole(HomeRole r) => role.value = r;

  bool get isPassenger => role.value == HomeRole.passenger;
}
