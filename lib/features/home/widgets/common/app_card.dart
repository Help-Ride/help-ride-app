import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.showShadow = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF232836) : const Color(0xFFE6EAF2),
        ),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  color: isDark
                      ? Colors.black.withOpacity(0.35)
                      : const Color(0x0A000000),
                ),
              ]
            : const [],
      ),
      child: child,
    );
  }
}
