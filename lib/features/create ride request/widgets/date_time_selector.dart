import 'package:flutter/material.dart';

class DateTimeSelector extends StatelessWidget {
  final IconData icon;
  final String displayText;
  final VoidCallback onTap;

  const DateTimeSelector({
    Key? key,
    required this.icon,
    required this.displayText,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                displayText,
                style: TextStyle(color: Colors.black),
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: Colors.black),
          ],
        ),
      ),
    );
  }
}
