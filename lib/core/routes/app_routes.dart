import 'package:get/get.dart';
import 'package:help_ride/features/profile/views/passenger_edit_profile.dart';
import 'package:help_ride/shared/bindings/shell_binding.dart';
import 'package:help_ride/shared/views/app_shell.dart';
import '../../features/auth/routes/auth_routes.dart';
import '../../features/profile/bindings/passenger_profile_binding.dart';
import '../../features/profile/bindings/edit_profile_binding.dart';
import '../../features/profile/views/passenger_profile_view.dart';
import '../../shared/views/splash_gate.dart';

class AppRoutes {
  static const gate = '/';
  static const shell = '/shell';
  static const login = '/login';
  static const register = '/register';

  static const passengerProfile = '/passenger-profile';
  static const editProfile = '/passenger-edit-profile';

  static final pages = [
    GetPage(name: gate, page: () => const SplashGate()),
    ...AuthRoutes.pages,
    GetPage(name: shell, page: () => const AppShell(), binding: ShellBinding()),
    GetPage(
      name: passengerProfile,
      page: () => const PassengerProfileView(),
      binding: PassengerProfileBinding(),
    ),
    GetPage(
      name: editProfile,
      page: () => const EditProfileView(),
      binding: EditProfileBinding(),
    ),
  ];
}
