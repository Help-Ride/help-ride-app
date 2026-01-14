import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../controllers/driver_requests_controller.dart';

class DriverRequestsTabs extends StatelessWidget {
  const DriverRequestsTabs({
    super.key,
    required this.active,
    required this.onChange,
    required this.newCount,
    required this.offeredCount,
  });

  final DriverRequestsTab active;
  final ValueChanged<DriverRequestsTab> onChange;
  final int newCount;
  final int offeredCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF2F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8F2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Pill(
              text: 'All Requests',
              active: active == DriverRequestsTab.all,
              onTap: () => onChange(DriverRequestsTab.all),
            ),
          ),
          Expanded(
            child: _Pill(
              text: newCount > 0 ? 'New  $newCount' : 'New',
              active: active == DriverRequestsTab.newRequests,
              onTap: () => onChange(DriverRequestsTab.newRequests),
            ),
          ),
          Expanded(
            child: _Pill(
              text: offeredCount > 0 ? 'Offered  $offeredCount' : 'Offered',
              active: active == DriverRequestsTab.offered,
              onTap: () => onChange(DriverRequestsTab.offered),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.active, required this.onTap});

  final String text;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: active
              ? const [
                  BoxShadow(
                    blurRadius: 12,
                    offset: Offset(0, 6),
                    color: Color(0x12000000),
                  ),
                ]
              : const [],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: active ? AppColors.lightText : AppColors.lightMuted,
          ),
        ),
      ),
    );
  }
}
