import 'package:flutter/material.dart';

class RideCard extends StatelessWidget {
  final String statusText;
  final String locationText;
  final String timeDateText;
  final String driverName;
  final String amountText;
  final Color statusColor;
  final Color statusTextColor;

  const RideCard({
    required this.statusText,
    required this.locationText,
    required this.driverName,
    required this.amountText,
    required this.timeDateText,
    required this.statusColor,
    required this.statusTextColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(

                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: statusTextColor,
                  ),
                ),
              ),
               Text(amountText, style: TextStyle(color: Colors.black,fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  locationText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14,color: Colors.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Divider(color: Colors.grey,thickness: 0.3,),

          const SizedBox(height: 12),
          Row(
            children:  [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              SizedBox(width: 6),
              Text(timeDateText, style: TextStyle(fontSize: 12,color: Colors.black)),
              Spacer(),

              Icon(Icons.person, size: 14, color: Colors.grey),
              SizedBox(width: 6),
              Text(driverName, style: TextStyle(fontSize: 12,color: Colors.black)),
            ],
          ),
        ],
      ),
    );
  }
}
