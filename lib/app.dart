import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:help_ride/core/theme/theme_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/routes/auth_routes.dart';
import 'features/auth/views/login_view.dart';

final themeController = Get.put(ThemeController(), permanent: true);

class HelpRideApp extends StatelessWidget {
  const HelpRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'HelpRide',
      debugShowCheckedModeBanner: false,
      darkTheme: AppTheme.dark(),
      themeMode: themeController.themeMode,
      initialRoute: AuthRoutes.login,
      getPages: AuthRoutes.pages,
      home: LoginView(), // fallback
    );
  }
}
