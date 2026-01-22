import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/my_rides_controller.dart';
import '../../widgets/my_ride_card.dart';
import '../../widgets/tab_switcher.dart';

// class MyRidesView extends StatelessWidget {
//   MyRidesView({super.key});
//
//   final MyRidesController controller = Get.put(MyRidesController());
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF9FAFB),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 'My Rides',
//                 style: TextStyle(
//                   color: Colors.black,
//                   fontSize: 22,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               const SizedBox(height: 16),
//               const TabSwitcher(),
//               const SizedBox(height: 20),
//
//               Expanded(
//                 child: Obx(() {
//                   if (controller.isLoading.value) {
//                     return const Center(child: CircularProgressIndicator());
//                   }
//
//                   final rides = controller.selectedTab.value == 0
//                       ? controller.upcomingRides
//                       : controller.pastRides;
//
//                   if (rides.isEmpty) {
//                     return const Center(child: Text('No rides found'));
//                   }
//
//                   return ListView.separated(
//                     itemCount: rides.length,
//                     separatorBuilder: (_, __) => const SizedBox(height: 14),
//                     itemBuilder: (_, index) {
//                       final ride = rides[index];
//                       final rideData = ride.ride!;
//
//                       final totalPrice =
//                           (int.tryParse(rideData.pricePerSeat ?? '0') ?? 0) *
//                               (ride.seatsBooked ?? 1);
//
//                       final isCompleted =
//                           controller.selectedTab.value == 1;
//
//                       return RideCard(
//                         locationText:
//                         '${rideData.fromCity} → ${rideData.toCity}',
//                         timeDateText:
//                         rideData.startTime?.toLocal().toString() ?? '',
//                         driverName: 'Driver', // API does not provide name
//                         statusText: isCompleted
//                             ? 'Completed'
//                             : ride.status?.capitalizeFirst ?? '',
//                         statusColor: isCompleted
//                             ? const Color(0xFFE5E7EB)
//                             : ride.status == 'confirmed'
//                             ? const Color(0xFFDCFCE7)
//                             : const Color(0xFFFEF3C7),
//                         statusTextColor: isCompleted
//                             ? Colors.black
//                             : ride.status == 'confirmed'
//                             ? const Color(0xFF16A34A)
//                             : const Color(0xFFD97706),
//                         amountText: '\$$totalPrice',
//                       );
//                     },
//                   );
//                 }),
//               ),
//
//
//               // Expanded(
//               //   child: Obx(() {
//               //     // ✅ Rx read HERE
//               //     final int tab = controller.selectedTab.value;
//               //
//               //     return ListView.separated(
//               //       itemCount: 2,
//               //       separatorBuilder: (_, __) => const SizedBox(height: 14),
//               //       itemBuilder: (_, index) {
//               //         return tab == 0
//               //             ? RideCard(
//               //                 locationText:
//               //                     "Downtown Toronto → Pearson Airport",
//               //                 timeDateText: "Today, 2:30 PM",
//               //                 driverName: "Sarah Johnson",
//               //                 statusText: index == 0 ? 'Confirmed' : 'Pending',
//               //                 statusColor: index == 0
//               //                     ? const Color(0xFFDCFCE7)
//               //                     : const Color(0xFFFEF3C7),
//               //                 statusTextColor: index == 0
//               //                     ? const Color(0xFF16A34A)
//               //                     : const Color(0xFFD97706),
//               //               )
//               //             : RideCard(
//               //                 locationText:
//               //                     "Downtown Toronto → Pearson Airport",
//               //                 timeDateText: "Today, 2:30 PM",
//               //                 driverName: "Sarah Johnson",
//               //                 statusText: 'Completed',
//               //                 statusColor: Color(0xFFE5E7EB),
//               //                 statusTextColor: Colors.black,
//               //               );
//               //       },
//               //     );
//               //   }),
//               // ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
class MyRidesView extends GetView<MyRidesController> {
  const MyRidesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Rides',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              /// pass controller to TabSwitcher
              TabSwitcher(controller: controller),

              const SizedBox(height: 20),

              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final rides = controller.selectedTab.value == 0
                      ? controller.upcomingRides
                      : controller.pastRides;

                  if (rides.isEmpty) {
                    return const Center(
                      child: Text(
                        'No rides found',
                        style: TextStyle(color: Colors.black),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: rides.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, index) {
                      final ride = rides[index];
                      final rideData = ride.ride!;

                      final totalPrice =
                          (int.tryParse(rideData.pricePerSeat ?? '0') ?? 0) *
                          (ride.seatsBooked ?? 1);

                      final isCompleted = controller.selectedTab.value == 1;

                      return RideCard(
                        locationText:
                            '${rideData.fromCity} → ${rideData.toCity}',
                        timeDateText: rideData.startTime != null
                            ? controller.formatRideDate(rideData.startTime!)
                            : '',

                        driverName: 'Driver',
                        // API does not provide name
                        statusText: isCompleted
                            ? 'Completed'
                            : ride.status?.capitalizeFirst ?? '',
                        statusColor: isCompleted
                            ? const Color(0xFFE5E7EB)
                            : ride.status == 'confirmed'
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEF3C7),
                        statusTextColor: isCompleted
                            ? Colors.black
                            : ride.status == 'confirmed'
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFD97706),
                        amountText: '\$$totalPrice',
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
