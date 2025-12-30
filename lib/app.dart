import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/routes/app_routes.dart';
import 'shared/controllers/session_controller.dart';

class HelpRideApp extends StatelessWidget {
  const HelpRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(ThemeController(), permanent: true);
    Get.put(SessionController(), permanent: true);

    final theme = Get.find<ThemeController>();

    return Obx(
      () => GetMaterialApp(
        title: 'HelpRide',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(theme.role.value),
        darkTheme: AppTheme.dark(theme.role.value),
        themeMode: theme.themeMode,
        initialRoute: AppRoutes.gate,
        getPages: AppRoutes.pages,
      ),
    );
  }
}
