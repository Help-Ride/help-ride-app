import 'package:get/get.dart';
import '../bindings/auth_binding.dart';
import '../views/login_view.dart';

class AuthRoutes {
  static const login = '/login';

  static final pages = [
    GetPage(name: login, page: () => LoginView(), binding: AuthBinding()),
  ];
}
