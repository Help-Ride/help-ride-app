import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  final String message;

  const InfoCard({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: Color(0xFF1976D2),
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
      ),
    );
  }
}