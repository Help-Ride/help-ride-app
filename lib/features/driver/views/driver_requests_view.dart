import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/driver_requests_controller.dart';
import '../widgets/requests/driver_request_card.dart';
import '../widgets/requests/driver_requests_tabs.dart';

class DriverRequestsView extends GetView<DriverRequestsController> {
  const DriverRequestsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: isDark ? AppColors.darkText : AppColors.lightText,
        title: const Text(
          'Booking Requests',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          child: Column(
            children: [
              Obx(() {
                final count = controller.newCount;
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    count == 1 ? '1 new request' : '$count new requests',
                    style: TextStyle(color: muted),
                  ),
                );
              }),
              const SizedBox(height: 12),
              Obx(
                () => DriverRequestsTabs(
                  active: controller.tab.value,
                  onChange: controller.setTab,
                  newCount: controller.newCount,
                  offeredCount: controller.offeredCount,
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
                  return Expanded(
                    child: Center(
                      child: Text(
                        'No booking requests yet.',
                        style: TextStyle(color: muted),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return Expanded(
                  child: RefreshIndicator(
                    onRefresh: controller.fetch,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 18),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (_, i) {
                        final b = list[i];
                        return DriverRequestCard(
                          booking: b,
                          busy: controller.isActing(b.id),
                          onConfirm: () => controller.confirm(b.id),
                          onReject: () => controller.reject(b.id),
                        );
                      },
                    ),
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
