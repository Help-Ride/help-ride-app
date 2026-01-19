import 'package:flutter/material.dart';

class PassengerProfileAvatar extends StatelessWidget {
  const PassengerProfileAvatar({
    super.key,
    required this.initials,
    this.avatarUrl,
    this.size = 56.0,
  });

  final String initials;
  final String? avatarUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hasAvatar ? null : const Color(0xFFE8E8E8),
        image: hasAvatar
            ? DecorationImage(
          image: NetworkImage(avatarUrl!),
          fit: BoxFit.cover,
        )
            : null,
      ),
      child: hasAvatar
          ? null
          : Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF666666),
          ),
        ),
      ),
    );
  }
}