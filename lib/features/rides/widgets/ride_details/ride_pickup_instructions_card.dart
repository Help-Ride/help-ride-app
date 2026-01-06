import 'package:flutter/material.dart';
import 'ride_ui.dart';

class RidePickupInstructionsCard extends StatelessWidget {
  const RidePickupInstructionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Text(
        'Will wait near the main entrance',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
