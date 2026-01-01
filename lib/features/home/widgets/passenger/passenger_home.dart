import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'where_to_card.dart';
import 'recent_search_tile.dart';

class PassengerHome extends StatelessWidget {
  const PassengerHome({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      children: const [
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
