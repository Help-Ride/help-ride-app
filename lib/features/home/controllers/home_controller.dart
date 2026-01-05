import 'package:get/get.dart';
import '../../../shared/controllers/session_controller.dart';

enum HomeRole { passenger, driver }

class HomeController extends GetxController {
  final role = HomeRole.passenger.obs;

  late final SessionController _session;

  @override
  void onInit() {
    super.onInit();
    _session = Get.find<SessionController>();
  }

  void setRole(HomeRole r) => role.value = r;

  /// Use a safe display name for the home header.
  /// - Prefer first name
  /// - Fallback to email prefix
  /// - Final fallback: "User"
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
