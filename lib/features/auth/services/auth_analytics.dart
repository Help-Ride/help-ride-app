import 'package:flutter/foundation.dart';

class AuthAnalytics {
  AuthAnalytics._();

  static void track(String event, [Map<String, Object?> properties = const {}]) {
    debugPrint('[auth_analytics] $event ${properties.isEmpty ? '' : properties}');
  }
}
