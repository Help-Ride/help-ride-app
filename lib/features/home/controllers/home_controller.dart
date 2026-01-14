import 'package:get/get.dart';
import 'package:help_ride/core/constants/app_constants.dart';
import 'package:help_ride/core/theme/theme_controller.dart';
import '../../../shared/controllers/session_controller.dart';

enum HomeRole { passenger, driver }

class HomeController extends GetxController {
  final role = HomeRole.passenger.obs;

  late final ThemeController _theme;
  late final SessionController _session;

  @override
  void onInit() {
    super.onInit();
    _theme = Get.find<ThemeController>();
    _session = Get.find<SessionController>();

    // sync initial
    role.value = _theme.role.value == AppRole.driver
        ? HomeRole.driver
        : HomeRole.passenger;

    // keep syncing if role changes elsewhere
    ever(_theme.role, (AppRole r) {
      role.value = r == AppRole.driver ? HomeRole.driver : HomeRole.passenger;
    });
  }

  void setRole(HomeRole r) {
    role.value = r;

    // persist + make it global
    _theme.switchRole(
      r == HomeRole.driver ? AppRole.driver : AppRole.passenger,
    );
  }

  String get headerName {
    final user = _session.user.value;

    final fullName = (user?.name ?? '').trim();
    if (fullName.isNotEmpty) {
      final first = fullName.split(RegExp(r'\s+')).first.trim();
      if (first.isNotEmpty) return first;
    }

    final email = (user?.email ?? '').trim();
    if (email.isNotEmpty && email.contains('@')) {
      final prefix = email.split('@').first.trim();
      if (prefix.isNotEmpty) return prefix;
    }

    return 'User';
  }
}

  /// - Final fallback: "User"


