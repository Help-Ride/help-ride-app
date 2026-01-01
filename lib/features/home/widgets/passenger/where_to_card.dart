import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../common/app_card.dart';

class WhereToCard extends StatefulWidget {
  const WhereToCard({super.key});

  @override
  State<WhereToCard> createState() => _WhereToCardState();
}

class _WhereToCardState extends State<WhereToCard> {
  final _pickupCtrl = TextEditingController();
  final _destCtrl = TextEditingController();

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _destCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Where to?",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),

          _TextFieldTile(
            controller: _pickupCtrl,
            icon: Icons.my_location,
            hintText: "Pickup location",
          ),
          const SizedBox(height: 12),

          _TextFieldTile(
            controller: _destCtrl,
            icon: Icons.place,
            iconColor: AppColors.passengerPrimary,
            hintText: "Destination",
          ),

          const SizedBox(height: 14),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: hook to search rides using _pickupCtrl.text and _destCtrl.text
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.passengerPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.search, size: 18),
              label: const Text(
                "Search rides",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // TODO: hook to create ride request
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE2E6EF)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "Create ride request",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.passengerPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextFieldTile extends StatelessWidget {
  const _TextFieldTile({
    required this.controller,
    required this.icon,
    required this.hintText,
    this.iconColor,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hintText;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? AppColors.lightMuted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 1,
              textAlignVertical: TextAlignVertical.center,
              cursorColor: AppColors.passengerPrimary,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(color: AppColors.lightMuted),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
            ),
          ),
        ],
      ),
    );
  }
}
