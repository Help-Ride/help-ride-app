import 'package:flutter/material.dart';

class RidePreviewCard extends StatelessWidget {
  const RidePreviewCard({
    super.key,
    required this.from,
    required this.to,
    required this.metaLeft,
    required this.metaRight,
  });

  final String from;
  final String to;
  final String metaLeft;
  final String metaRight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 34,
            offset: Offset(0, 18),
            color: Color(0x22000000),
          ),
        ],
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "RIDE PREVIEW",
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              "From\n$from",
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              "To\n$to",
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: Text(metaLeft)),
                Text(
                  metaRight,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
