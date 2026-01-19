import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:help_ride/features/book_rides/screens/book_rides_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../book_rides/Models/book_rides_data.dart';
import 'where_to_card.dart';
import 'recent_search_tile.dart';

// class PassengerHome extends StatelessWidget {
//   const PassengerHome({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return ListView(
//       padding: const EdgeInsets.only(bottom: 8),
//       children: [
//         WhereToCard(),
//         SizedBox(height: 18),
//         Text(
//           "RECENT SEARCHES",
//           style: TextStyle(
//             color: AppColors.lightMuted,
//             fontWeight: FontWeight.w800,
//             letterSpacing: 1,
//           ),
//         ),
//         SizedBox(height: 10),
//         RecentSearchTile(
//           from: "Downtown Toronto",
//           to: "Pearson Airport",
//           when: "Today, 2:30 PM",
//           onTap: () {
//             Get.to(BookRidesScreen());
//           },
//         ),
//         RecentSearchTile(
//           from: "Montreal",
//           to: "Ottawa",
//           when: "Dec 20, 9:00 AM",
//         ),
//         RecentSearchTile(
//           from: "Mississauga",
//           to: "Downtown Toronto",
//           when: "Dec 18, 5:00 PM",
//         ),
//       ],
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../controllers/home_controller.dart';
import 'where_to_card.dart';
import 'recent_search_tile.dart';

class PassengerHome extends GetView<HomeController> {
  const PassengerHome({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        const WhereToCard(),
        const SizedBox(height: 18),

        Text(
          "RECENT SEARCHES",
          style: TextStyle(
            color: AppColors.lightMuted,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),

        Obx(() {
          if (controller.recentSearches.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text("No recent searches",style: TextStyle(color: Colors.black),),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.recentSearches.length,
            itemBuilder: (_, index) {
              final ride = controller.recentSearches[index];

              return RecentSearchTile(
                from: ride.fromCity ?? '',
                to: ride.toCity ?? '',
                // when: ride.startTime?.toString() ?? '',
                when: controller.formatRideTime(ride.startTime.toString() ?? ''),

                onTap: () {
                  controller.searchRides(
                    fromCity: ride.fromCity ?? '',
                    toCity: ride.toCity ?? '',
                    seats: 1,
                  ).then((_) {
                    Get.to(() => BookRidesScreen(
                      params: SearchParams(
                        fromCity: ride.fromCity ?? '',
                        toCity: ride.toCity ?? '',
                        when: controller.formatRideTime(ride.startTime.toString() ?? ''),
                      ),
                      rides: controller.recentSearches,
                    ));
                  });
                },

              );
            },
          );
        }),
      ],
    );
  }
}
