import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../controllers/recent_searches_controller.dart';
import 'where_to_card.dart';
import 'recent_search_tile.dart';

class PassengerHome extends StatefulWidget {
  const PassengerHome({super.key});

  @override
  State<PassengerHome> createState() => _PassengerHomeState();
}

class _PassengerHomeState extends State<PassengerHome> {
  late final RecentSearchesController _recent;

  @override
  void initState() {
    super.initState();
    _recent = Get.isRegistered<RecentSearchesController>()
        ? Get.find<RecentSearchesController>()
        : Get.put(RecentSearchesController());
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final items = _recent.items;
      final children = <Widget>[
        const WhereToCard(),
        const SizedBox(height: 18),
      ];

      if (items.isNotEmpty) {
        children.addAll([
          Text(
            "RECENT SEARCHES",
            style: TextStyle(
              color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
        ]);

        for (final item in items) {
          children.add(
            RecentSearchTile(
              from: item.from,
              to: item.to,
              when: _recent.formatWhen(item.when),
              onTap: () {
                final seats = item.seats ?? 1;
                Get.toNamed(
                  '/rides/search',
                  arguments: {
                    'fromCity': item.from,
                    'toCity': item.to,
                    'seats': seats,
                    if (item.fromLat != null) 'fromLat': item.fromLat,
                    if (item.fromLng != null) 'fromLng': item.fromLng,
                    if (item.toLat != null) 'toLat': item.toLat,
                    if (item.toLng != null) 'toLng': item.toLng,
                    if (item.radiusKm != null) 'radiusKm': item.radiusKm,
                  },
                );
              },
            ),
          );
        }
      }

      return ListView(
        padding: const EdgeInsets.only(bottom: 8),
        children: children,
      );
    });
  }
}
