import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:help_ride/core/constants/app_constants.dart';

class ThemeController extends GetxController {
  static const _roleKey = 'app_role';

  final _box = GetStorage();

  final isDark = false.obs;
  final role = AppRole.passenger.obs;

  ThemeMode get themeMode => ThemeMode.system;

  late final _ThemeBindingObserver _observer;

  @override
  void onInit() {
    super.onInit();
    _observer = _ThemeBindingObserver(this);
    WidgetsBinding.instance.addObserver(_observer);

    _syncBrightness();

    final savedRole = _box.read(_roleKey);
    if (savedRole == 'driver') {
      role.value = AppRole.driver;
    }
  }

  void switchRole(AppRole newRole) {
    role.value = newRole;
    _box.write(_roleKey, newRole.name);
  }

  void _syncBrightness() {
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    isDark.value = brightness == Brightness.dark;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(_observer);
    super.onClose();
  }
}

class _ThemeBindingObserver with WidgetsBindingObserver {
  _ThemeBindingObserver(this._controller);
  final ThemeController _controller;

  @override
  void didChangePlatformBrightness() {
    _controller._syncBrightness();
  }
}
