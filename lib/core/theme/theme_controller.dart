import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:help_ride/core/constants/app_constants.dart';

class ThemeController extends GetxController {
  static const _darkKey = 'is_dark_theme';
  static const _roleKey = 'app_role';

  final _box = GetStorage();

  final isDark = true.obs;
  final role = AppRole.passenger.obs;

  ThemeMode get themeMode => isDark.value ? ThemeMode.dark : ThemeMode.light;

  @override
  void onInit() {
    super.onInit();

    final savedDark = _box.read(_darkKey);
    if (savedDark is bool) isDark.value = savedDark;

    final savedRole = _box.read(_roleKey);
    if (savedRole == 'driver') {
      role.value = AppRole.driver;
    }
  }

  void toggleTheme() {
    isDark.toggle();
    _box.write(_darkKey, isDark.value);
  }

  void switchRole(AppRole newRole) {
    role.value = newRole;
    _box.write(_roleKey, newRole.name);
  }
}
