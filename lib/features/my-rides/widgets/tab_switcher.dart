import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/my_rides_controller.dart';

class TabSwitcher extends StatelessWidget {
  final MyRidesController? controller;

  const TabSwitcher({super.key,this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: const [
          TabItem(title: 'Upcoming', index: 0),
          TabItem(title: 'Past', index: 1),
        ],
      ),
    );
  }
}

class TabItem extends GetView<MyRidesController> {
  final String title;
  final int index;

  const TabItem({required this.title, required this.index, super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Obx(() {
        final bool isSelected = controller.selectedTab.value == index;

        return GestureDetector(
          onTap: () => controller.changeTab(index),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.black : Colors.grey.shade600,
              ),
            ),
          ),
        );
      }),
    );
  }
}
