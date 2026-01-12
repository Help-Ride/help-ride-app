import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/my_rides_controller.dart';
import '../models/booking.dart';

class MyRidesView extends GetView<MyRidesController> {
  const MyRidesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.lightBg,
        elevation: 0,
        foregroundColor: AppColors.lightText,
        title: const Text(
          'My Rides',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          child: Column(
            children: [
              Obx(
                () => _Tabs(
                  active: controller.tab.value,
                  onChange: controller.setTab,
                ),
              ),
              const SizedBox(height: 14),

              Obx(() {
                if (controller.loading.value) {
                  return const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final err = controller.error.value;
                if (err != null) {
                  return Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            err,
                            style: const TextStyle(color: AppColors.error),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: controller.fetch,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final list = controller.filtered;
                if (list.isEmpty) {
                  return const Expanded(
                    child: Center(
                      child: Text(
                        'No rides yet.',
                        style: TextStyle(color: AppColors.lightMuted),
                      ),
                    ),
                  );
                }

                return Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 18),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, i) => _BookingCard(b: list[i]),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.active, required this.onChange});

  final MyRidesTab active;
  final ValueChanged<MyRidesTab> onChange;

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
            child: _TabPill(
              text: 'Upcoming',
              active: active == MyRidesTab.upcoming,
              onTap: () => onChange(MyRidesTab.upcoming),
            ),
          ),
          Expanded(
            child: _TabPill(
              text: 'Past',
              active: active == MyRidesTab.past,
              onTap: () => onChange(MyRidesTab.past),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.text,
    required this.active,
    required this.onTap,
  });

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

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.b});
  final Booking b;

  @override
  Widget build(BuildContext context) {
    final status = b.status.toLowerCase();
    final pill = _statusPill(status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EAF2)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 10),
            color: Color(0x0A000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // status + price
          Row(
            children: [
              pill,
              const Spacer(),
              Text(
                '\$${b.totalPrice.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // route
          Row(
            children: [
              const Icon(
                Icons.place_outlined,
                size: 18,
                color: AppColors.lightMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${b.ride.fromCity}  →  ${b.ride.toCity}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE9EEF6)),
          const SizedBox(height: 12),

          // meta row
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppColors.lightMuted,
              ),
              const SizedBox(width: 6),
              Text(
                _formatDate(b.ride.startTime),
                style: const TextStyle(color: AppColors.lightMuted),
              ),
              const SizedBox(width: 14),
              const Icon(
                Icons.person_outline,
                size: 18,
                color: AppColors.lightMuted,
              ),
              const SizedBox(width: 6),
              Text(
                b.ride.driverId.substring(0, 6),
                style: const TextStyle(color: AppColors.lightMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String s) {
    Color bg;
    Color fg;
    String text;

    if (s.contains('confirmed')) {
      bg = const Color(0xFFE7F8EF);
      fg = const Color(0xFF179C5E);
      text = 'Confirmed';
    } else if (s.contains('pending')) {
      bg = const Color(0xFFFFF2D6);
      fg = const Color(0xFFB86B00);
      text = 'Pending';
    } else if (s.contains('cancel')) {
      bg = const Color(0xFFFFE2E2);
      fg = const Color(0xFFD64545);
      text = 'Cancelled';
    } else if (s.contains('completed')) {
      bg = const Color(0xFFEFF2F6);
      fg = const Color(0xFF6B7280);
      text = 'Completed';
    } else {
      bg = const Color(0xFFEFF2F6);
      fg = const Color(0xFF6B7280);
      text = s;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}

String _formatDate(DateTime dt) {
  final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  final mm = dt.minute.toString().padLeft(2, '0');
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[(dt.month - 1)]} ${dt.day}, $h:$mm $ampm';
}
