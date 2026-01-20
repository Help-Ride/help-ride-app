import 'dart:io';
import 'package:flutter/material.dart';

class PassengerProfileAvatar extends StatelessWidget {
  final String initials;
  final String? avatarUrl;
  final double size;

  const PassengerProfileAvatar({
    super.key,
    required this.initials,
    this.avatarUrl,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrl == null || avatarUrl!.isEmpty) {
      return CircleAvatar(
        radius: size / 2,
        child: Text(initials),
      );
    }

    // Local file image
    if (avatarUrl!.startsWith('/') || avatarUrl!.startsWith('file://')) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: FileImage(File(avatarUrl!)),
      );
    }

    // Network image
    return CircleAvatar(
      radius: size / 2,
      backgroundImage: NetworkImage(avatarUrl!),
    );
  }
}
