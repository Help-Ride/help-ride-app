import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.fallbackText,
    this.radius = 22,
    this.backgroundColor,
    this.foregroundColor,
    this.textStyle,
  });

  final String name;
  final String? avatarUrl;
  final String? fallbackText;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final resolvedAvatarUrl = (avatarUrl ?? '').trim();
    final resolvedFallback = (fallbackText ?? '').trim();
    final resolvedForeground =
        foregroundColor ?? Theme.of(context).primaryColor;

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: resolvedAvatarUrl.isNotEmpty
          ? NetworkImage(resolvedAvatarUrl)
          : null,
      child: resolvedAvatarUrl.isEmpty
          ? Text(
              resolvedFallback.isNotEmpty ? resolvedFallback : _initials(name),
              style:
                  textStyle ??
                  TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: radius * 0.72,
                    color: resolvedForeground,
                  ),
            )
          : null,
    );
  }
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'U';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}
