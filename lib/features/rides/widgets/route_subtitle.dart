import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class RouteSubtitle extends StatelessWidget {
  const RouteSubtitle({
    super.key,
    required this.fromCity,
    required this.toCity,
  });

  final String fromCity;
  final String toCity;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$fromCity  →  $toCity',
      style: const TextStyle(
        color: AppColors.lightMuted,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
