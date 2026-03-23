import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AuthTopBar extends StatelessWidget {
  const AuthTopBar({
    super.key,
    this.onBack,
    this.onClose,
  });

  final VoidCallback? onBack;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? AppColors.darkText : AppColors.lightText;
    final chipColor = isDark ? const Color(0xFF151B25) : const Color(0xFFF3F5F8);
    final borderColor = isDark
        ? const Color(0xFF2A3242)
        : const Color(0xFFDCE3EE);

    Widget action({
      required IconData icon,
      required VoidCallback onPressed,
    }) {
      return InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: chipColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
      );
    }

    return Row(
      children: [
        if (onBack != null)
          action(icon: Icons.arrow_back_rounded, onPressed: onBack!)
        else
          const SizedBox(width: 42, height: 42),
        const Spacer(),
        if (onClose != null)
          action(icon: Icons.close_rounded, onPressed: onClose!)
        else
          const SizedBox(width: 42, height: 42),
      ],
    );
  }
}
