import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../common/app_card.dart';
import '../common/input_field_tile.dart';

class WhereToCard extends StatelessWidget {
  const WhereToCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Where to?",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          InputFieldTile(
            icon: Icons.my_location,
            label: "Pickup location",
            onTap: () {
              // TODO: open pickup search sheet
            },
          ),
          const SizedBox(height: 12),
          InputFieldTile(
            icon: Icons.place,
            iconColor: AppColors.passengerPrimary,
            label: "Destination",
            onTap: () {
              // TODO: open destination search sheet
            },
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.passengerPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.search, size: 18),
              label: const Text(
                "Search rides",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE2E6EF)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "Create ride request",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.passengerPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
