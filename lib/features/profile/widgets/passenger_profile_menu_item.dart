import 'package:flutter/material.dart';

class PassengerProfileMenuItem extends StatelessWidget {
  const PassengerProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isDestructive
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF666666),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDestructive
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF1A1A1A),
                        height: 1.3,
                      ),
                    ),
                  ),
                  if (!isDestructive)
                    const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: Color(0xFFCCCCCC),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 56),
            child: Container(
              height: 1,
              color: const Color(0xFFF5F5F5),
            ),
          ),
      ],
    );
  }
}