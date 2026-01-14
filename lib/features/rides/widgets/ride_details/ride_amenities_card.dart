import 'package:flutter/material.dart';
import 'ride_ui.dart';

class RideAmenitiesCard extends StatelessWidget {
  const RideAmenitiesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: const [Tag('AC'), Tag('Music'), Tag('Pet-friendly')],
      ),
    );
  }
}
