import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../features/driver/routes/driver_routes.dart';
import '../../../shared/services/api_client.dart';
import '../../../shared/services/notifications_api.dart';
import '../../../shared/services/push_notification_service.dart';
import '../models/app_notification.dart';

class NotificationCenterController extends GetxController
    with WidgetsBindingObserver {
  static const int _pageSize = 80;

  late final NotificationsApi _api;
  StreamSubscription<void>? _notificationEventsSub;
  Timer? _refreshDebounce;

  final notifications = <AppNotificationItem>[].obs;
  final loading = false.obs;
  final refreshing = false.obs;
  final markAllLoading = false.obs;
  final error = RxnString();
  bool _ready = false;

  @override
  Future<void> onInit() async {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);

    final client = await ApiClient.create();
    _api = NotificationsApi(client);
    _ready = true;

    _notificationEventsSub = PushNotificationService.instance.notificationEvents
        .listen((_) {
          _scheduleRefresh();
        });

    await fetchNotifications();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationEventsSub?.cancel();
    _refreshDebounce?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleRefresh();
    }
  }

  Future<void> fetchNotifications({bool silent = false}) async {
    if (!_ready) return;
    if (loading.value || refreshing.value) return;

    if (silent && notifications.isNotEmpty) {
      refreshing.value = true;
    } else {
      loading.value = true;
    }
    error.value = null;

    try {
      final page = await _api.listNotifications(limit: _pageSize);
      final mapped = page.notifications
          .map(
            (item) => AppNotificationItem.fromJson(
              item,
              navigationTarget: PushNotificationService.instance
                  .lookupCachedNotificationTarget(
                    (item['id'] ?? '').toString().trim(),
                  ),
            ),
          )
          .toList();
      notifications.assignAll(mapped);
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
      refreshing.value = false;
    }
  }

  Future<void> markRead(String notificationId) async {
    final id = notificationId.trim();
    if (id.isEmpty) return;

    final index = notifications.indexWhere((item) => item.id == id);
    if (index == -1 || notifications[index].isRead) return;

    final current = notifications[index];
    notifications[index] = AppNotificationItem(
      id: current.id,
      title: current.title,
      body: current.body,
      type: current.type,
      isRead: true,
      createdAt: current.createdAt,
      navigationTarget: current.navigationTarget,
      kind: current.kind,
      category: current.category,
      audience: current.audience,
      priority: current.priority,
    );

    try {
      await _api.markRead(id);
    } catch (_) {
      notifications[index] = current;
      rethrow;
    }
  }

  Future<void> markAllRead() async {
    if (markAllLoading.value || unreadCount == 0) return;
    markAllLoading.value = true;

    final previous = [...notifications];
    notifications.assignAll(
      previous
          .map(
            (item) => AppNotificationItem(
              id: item.id,
              title: item.title,
              body: item.body,
              type: item.type,
              isRead: true,
              createdAt: item.createdAt,
              navigationTarget: item.navigationTarget,
              kind: item.kind,
              category: item.category,
              audience: item.audience,
              priority: item.priority,
            ),
          )
          .toList(),
    );

    try {
      await _api.markAllRead();
    } catch (_) {
      notifications.assignAll(previous);
      rethrow;
    } finally {
      markAllLoading.value = false;
    }
  }

  Future<void> openNotification(AppNotificationItem item) async {
    if (!item.isRead) {
      try {
        await markRead(item.id);
      } catch (_) {
        // Best effort; still allow navigation.
      }
    }

    if (Get.isBottomSheetOpen ?? false) {
      Get.back<void>();
      await Future<void>.delayed(const Duration(milliseconds: 180));
    }

    if (item.hasNavigationTarget) {
      await PushNotificationService.instance.navigateToNotificationTarget(
        item.navigationTarget,
      );
      return;
    }

    await _openFallbackDestination(item);
  }

  int get unreadCount => notifications.where((item) => !item.isRead).length;

  AppNotificationItem? urgentNotificationForRole(AppRole role) {
    for (final item in notifications) {
      if (item.shouldShowInlineForRole(role)) {
        return item;
      }
    }
    return null;
  }

  List<NotificationSection> get sections {
    final now = DateTime.now();
    final today = <AppNotificationItem>[];
    final thisWeek = <AppNotificationItem>[];
    final earlier = <AppNotificationItem>[];

    for (final item in notifications) {
      final createdAt = item.createdAt;
      if (_isSameDay(createdAt, now)) {
        today.add(item);
      } else if (now.difference(createdAt).inDays < 7) {
        thisWeek.add(item);
      } else {
        earlier.add(item);
      }
    }

    final grouped = <NotificationSection>[];
    if (today.isNotEmpty) {
      grouped.add(NotificationSection(title: 'Today', items: today));
    }
    if (thisWeek.isNotEmpty) {
      grouped.add(NotificationSection(title: 'This Week', items: thisWeek));
    }
    if (earlier.isNotEmpty) {
      grouped.add(NotificationSection(title: 'Earlier', items: earlier));
    }
    return grouped;
  }

  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 350), () {
      fetchNotifications(silent: true);
    });
  }

  Future<void> _openFallbackDestination(AppNotificationItem item) async {
    if (item.category == AppNotificationCategory.messagesPreview) {
      await PushNotificationService.instance.openShellTab('messages');
      return;
    }

    if (item.category == AppNotificationCategory.account) {
      await PushNotificationService.instance.openShellTab('profile');
      return;
    }

    if (item.audience == AppNotificationAudience.driver) {
      await Get.toNamed(
        DriverRoutes.rideRequests,
        arguments: {'tab': item.kind.contains('offer') ? 'offers' : 'requests'},
      );
      return;
    }

    if (item.audience == AppNotificationAudience.passenger) {
      final tab = item.kind.contains('request') ? 'requests' : 'upcoming';
      await PushNotificationService.instance.openShellTab(
        'rides',
        arguments: {'tab': tab},
        resetPassengerRidesController: true,
      );
      return;
    }

    if (item.category == AppNotificationCategory.payments ||
        item.category == AppNotificationCategory.rideUpdates) {
      await PushNotificationService.instance.openShellTab(
        'rides',
        arguments: const {'tab': 'upcoming'},
        resetPassengerRidesController: true,
      );
      return;
    }

    await PushNotificationService.instance.openShellTab('home');
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}
