import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../controllers/profile_controller.dart';

class StripeConnectReturnView extends StatefulWidget {
  const StripeConnectReturnView({super.key});

  @override
  State<StripeConnectReturnView> createState() =>
      _StripeConnectReturnViewState();
}

class _StripeConnectReturnViewState extends State<StripeConnectReturnView> {
  @override
  void initState() {
    super.initState();
    unawaited(_completeReturnFlow());
  }

  Future<void> _completeReturnFlow() async {
    if (Get.isRegistered<ProfileController>()) {
      try {
        await Get.find<ProfileController>().refreshStripeConnectStatus(
          silent: true,
        );
      } catch (_) {
        // Best-effort refresh before redirecting back to profile.
      }
    }

    if (!mounted) return;
    Get.offAllNamed(AppRoutes.shell, arguments: const {'tab': 'profile'});
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
