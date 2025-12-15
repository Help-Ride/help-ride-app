import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  static const _key = 'is_dark_theme';
  final _box = GetStorage();

  final isDark = true.obs;

  ThemeMode get themeMode => isDark.value ? ThemeMode.dark : ThemeMode.light;

  @override
  void onInit() {
    super.onInit();
    final saved = _box.read(_key);
    if (saved is bool) {
      isDark.value = saved;
    }
  }

  void toggleTheme() {
    isDark.value = !isDark.value;
    _box.write(_key, isDark.value);
  }

  void setDark(bool value) {
    isDark.value = value;
    _box.write(_key, value);
  }
}
