import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SelectChip extends StatelessWidget {
  const SelectChip({
    super.key,
    required this.text,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  final String text;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: active ? activeColor.withOpacity(0.12) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? activeColor : const Color(0xFFE2E6EF),
              width: 1.4,
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: active ? activeColor : AppColors.lightText,
            ),
          ),
        ),
      ),
    );
  }
}
