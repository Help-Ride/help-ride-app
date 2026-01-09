import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:help_ride/features/book_rides/screens/book_rides_screen.dart';
import '../../../../core/theme/app_colors.dart';
import 'where_to_card.dart';
import 'recent_search_tile.dart';

class PassengerHome extends StatelessWidget {
  const PassengerHome({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        WhereToCard(),
        SizedBox(height: 18),
        Text(
          "RECENT SEARCHES",
          style: TextStyle(
            color: AppColors.lightMuted,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: 10),
        RecentSearchTile(
          from: "Downtown Toronto",
          to: "Pearson Airport",
          when: "Today, 2:30 PM",
          onTap: () {
            Get.to(BookRidesScreen());
          },
        ),
        RecentSearchTile(
          from: "Montreal",
          to: "Ottawa",
          when: "Dec 20, 9:00 AM",
        ),
        RecentSearchTile(
          from: "Mississauga",
          to: "Downtown Toronto",
          when: "Dec 18, 5:00 PM",
        ),
      ],
    );
  }
}
