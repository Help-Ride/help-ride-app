import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/routes/auth_routes.dart';
import 'features/auth/views/login_view.dart';

class HelpRideApp extends StatelessWidget {
  const HelpRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'HelpRide',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: AuthRoutes.login,
      getPages: AuthRoutes.pages,
      home: LoginView(), // fallback
    );
  }
}
