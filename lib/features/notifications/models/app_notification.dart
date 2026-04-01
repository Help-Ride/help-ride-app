import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

enum AppNotificationCategory {
  rideUpdates,
  payments,
  messagesPreview,
  account,
  promotions,
  informational,
}

enum AppNotificationAudience { passenger, driver, both }

enum AppNotificationPriority { urgent, standard, low }

class AppNotificationItem {
  AppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    required this.navigationTarget,
    required this.kind,
    required this.category,
    required this.audience,
    required this.priority,
  });

  factory AppNotificationItem.fromJson(
    Map<String, dynamic> json, {
    Map<String, String>? navigationTarget,
  }) {
    final target = {
      ..._readNavigationTarget(json['data']),
      ...Map<String, String>.from(navigationTarget ?? const {}),
    };
    final title = (json['title'] ?? '').toString().trim();
    final body = (json['body'] ?? '').toString().trim();
    final type = (json['type'] ?? 'system').toString().trim().toLowerCase();
    final kind = _inferKind(
      title: title,
      body: body,
      type: type,
      navigationTarget: target,
    );

    return AppNotificationItem(
      id: (json['id'] ?? '').toString().trim(),
      title: title,
      body: body,
      type: type,
      isRead: json['isRead'] == true,
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
      navigationTarget: target,
      kind: kind,
      category: _resolveCategory(
        kind: kind,
        title: title,
        body: body,
        type: type,
      ),
      audience: _resolveAudience(kind: kind, title: title, body: body),
      priority: _resolvePriority(
        kind: kind,
        title: title,
        body: body,
        type: type,
      ),
    );
  }

  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, String> navigationTarget;
  final String kind;
  final AppNotificationCategory category;
  final AppNotificationAudience audience;
  final AppNotificationPriority priority;

  bool get hasNavigationTarget => navigationTarget.isNotEmpty;

  bool shouldShowInlineForRole(AppRole role) {
    if (isRead || priority != AppNotificationPriority.urgent) {
      return false;
    }
    if (category == AppNotificationCategory.messagesPreview ||
        category == AppNotificationCategory.promotions ||
        category == AppNotificationCategory.informational ||
        category == AppNotificationCategory.account) {
      return false;
    }
    if (audience == AppNotificationAudience.both) return true;
    return role == AppRole.driver
        ? audience == AppNotificationAudience.driver
        : audience == AppNotificationAudience.passenger;
  }

  String get categoryLabel {
    return switch (category) {
      AppNotificationCategory.rideUpdates => 'Ride update',
      AppNotificationCategory.payments => 'Payment',
      AppNotificationCategory.messagesPreview => 'Message',
      AppNotificationCategory.account => 'Account',
      AppNotificationCategory.promotions => 'Promotion',
      AppNotificationCategory.informational => 'Info',
    };
  }

  String get actionLabel {
    if (category == AppNotificationCategory.messagesPreview) {
      return 'Open chat';
    }
    if (kind.contains('payment') || kind.contains('payout')) {
      return kind.contains('failed') || kind.contains('required')
          ? 'Review'
          : 'Open';
    }
    if (kind.contains('request') || kind.contains('booking')) {
      return 'Review';
    }
    if (kind.contains('cancelled') ||
        kind.contains('updated') ||
        kind.contains('accepted') ||
        kind.contains('confirmed')) {
      return 'View';
    }
    if (category == AppNotificationCategory.account) {
      return 'Check';
    }
    return 'Open';
  }

  IconData get icon {
    if (category == AppNotificationCategory.messagesPreview) {
      return Icons.chat_bubble_rounded;
    }
    if (category == AppNotificationCategory.payments) {
      return kind.contains('payout')
          ? Icons.account_balance_wallet_rounded
          : Icons.credit_card_rounded;
    }
    if (category == AppNotificationCategory.account) {
      return Icons.verified_user_rounded;
    }
    if (category == AppNotificationCategory.promotions) {
      return Icons.local_offer_rounded;
    }
    if (kind.contains('cancelled') || kind.contains('failed')) {
      return Icons.warning_amber_rounded;
    }
    if (kind.contains('soon') || kind.contains('arriving')) {
      return Icons.schedule_rounded;
    }
    if (kind.contains('request') || kind.contains('booking_request')) {
      return Icons.alt_route_rounded;
    }
    return Icons.directions_car_filled_rounded;
  }

  Color accentColor({required bool isDark}) {
    if (category == AppNotificationCategory.payments) {
      return const Color(0xFFD99100);
    }
    if (category == AppNotificationCategory.messagesPreview) {
      return const Color(0xFF4B72FF);
    }
    if (category == AppNotificationCategory.account) {
      return const Color(0xFF6B5CFF);
    }
    if (category == AppNotificationCategory.promotions) {
      return const Color(0xFFE85D75);
    }
    if (audience == AppNotificationAudience.driver) {
      return AppColors.driverPrimary;
    }
    return AppColors.passengerPrimary;
  }
}

class NotificationSection {
  const NotificationSection({required this.title, required this.items});

  final String title;
  final List<AppNotificationItem> items;
}

Map<String, String> _readNavigationTarget(dynamic raw) {
  if (raw is! Map) return const <String, String>{};

  final target = <String, String>{};
  for (final entry in raw.entries) {
    final key = entry.key.toString().trim();
    final value = entry.value?.toString().trim() ?? '';
    if (key.isEmpty || value.isEmpty) continue;
    target[key] = value;
  }
  return target;
}

String _inferKind({
  required String title,
  required String body,
  required String type,
  required Map<String, String> navigationTarget,
}) {
  final explicitKind = (navigationTarget['kind'] ?? '').trim().toLowerCase();
  if (explicitKind.isNotEmpty) return explicitKind;

  final haystack = '$title $body'.toLowerCase();
  if (haystack.contains('new message')) return 'chat_message';
  if (haystack.contains('payment required')) return 'booking_payment_required';
  if (haystack.contains('payment failed')) return 'booking_payment_failed';
  if (haystack.contains('payment pending')) return 'booking_payment_pending';
  if (haystack.contains('payment successful') ||
      haystack.contains('payment was received')) {
    return 'booking_payment_succeeded';
  }
  if (haystack.contains('refund')) return 'booking_refunded';
  if (haystack.contains('payout')) return 'driver_payout_initiated';
  if (haystack.contains('pickup soon') || haystack.contains('arriving in')) {
    return 'pickup_soon';
  }
  if (haystack.contains('booking accepted') ||
      haystack.contains('booking confirmed') ||
      haystack.contains('driver matched')) {
    return 'booking_confirmed';
  }
  if (haystack.contains('booking rejected')) return 'booking_rejected';
  if (haystack.contains('booking request')) return 'booking_request';
  if (haystack.contains('ride request')) {
    if (haystack.contains('updated')) return 'ride_request_updated';
    if (haystack.contains('cancelled')) return 'ride_request_cancelled';
    if (haystack.contains('accepted')) return 'ride_request_accepted';
    if (haystack.contains('offer')) return 'ride_request_offer_created';
    return 'ride_request_created_nearby';
  }
  if (haystack.contains('ride cancelled') ||
      haystack.contains('was cancelled')) {
    return 'ride_cancelled_by_driver';
  }
  if (haystack.contains('pickup updated') ||
      haystack.contains('ride updated') ||
      haystack.contains('details changed')) {
    return 'ride_updated';
  }
  if (haystack.contains('ride starts soon') ||
      haystack.contains('starts soon')) {
    return 'ride_starts_soon';
  }
  if (haystack.contains('ride completed')) return 'ride_completed';
  if (haystack.contains('verify') ||
      haystack.contains('verification') ||
      haystack.contains('onboarding') ||
      haystack.contains('account')) {
    return 'account_update';
  }
  if (haystack.contains('promo') ||
      haystack.contains('discount') ||
      haystack.contains('coupon') ||
      haystack.contains('welcome')) {
    return 'promotion';
  }
  if (type == 'payment') return 'payment_update';
  return 'general';
}

AppNotificationCategory _resolveCategory({
  required String kind,
  required String title,
  required String body,
  required String type,
}) {
  final haystack = '$title $body'.toLowerCase();
  if (kind == 'chat_message') return AppNotificationCategory.messagesPreview;
  if (type == 'payment' ||
      kind.contains('payment') ||
      kind.contains('refund') ||
      kind.contains('payout')) {
    return AppNotificationCategory.payments;
  }
  if (kind.contains('account') ||
      haystack.contains('verify') ||
      haystack.contains('verification') ||
      haystack.contains('onboarding') ||
      haystack.contains('account')) {
    return AppNotificationCategory.account;
  }
  if (kind == 'promotion') return AppNotificationCategory.promotions;
  if (kind.startsWith('ride_') ||
      kind.startsWith('booking_') ||
      kind.startsWith('pickup_')) {
    return AppNotificationCategory.rideUpdates;
  }
  if (kind.startsWith('ride_request')) {
    return AppNotificationCategory.rideUpdates;
  }
  if (type == 'ride_update') return AppNotificationCategory.rideUpdates;
  if (haystack.contains('promo') ||
      haystack.contains('discount') ||
      haystack.contains('coupon')) {
    return AppNotificationCategory.promotions;
  }
  return AppNotificationCategory.informational;
}

AppNotificationAudience _resolveAudience({
  required String kind,
  required String title,
  required String body,
}) {
  const driverKinds = <String>{
    'booking_request',
    'booking_cancelled_by_passenger',
    'booking_payment_pending',
    'driver_booking_paid',
    'driver_booking_payment_failed',
    'driver_booking_refunded',
    'driver_payout_initiated',
    'ride_request_created',
    'ride_request_created_nearby',
    'ride_request_created_jit',
    'ride_request_updated',
    'ride_request_cancelled_by_passenger',
    'ride_request_offer_accepted',
    'ride_request_offer_not_selected',
    'ride_request_offer_rejected',
    'ride_request_assigned_driver',
    'ride_starts_soon',
  };
  const passengerKinds = <String>{
    'booking_confirmed',
    'booking_rejected',
    'booking_payment_required',
    'booking_payment_failed',
    'booking_payment_succeeded',
    'booking_refunded',
    'booking_cancelled_by_driver',
    'ride_updated',
    'pickup_soon',
    'ride_started',
    'ride_completed',
    'ride_cancelled_by_driver',
    'ride_request_accepted',
    'ride_request_offer_created',
    'ride_request_offer_cancelled',
    'ride_request_cancelled',
  };

  if (driverKinds.contains(kind)) return AppNotificationAudience.driver;
  if (passengerKinds.contains(kind)) return AppNotificationAudience.passenger;

  final haystack = '$title $body'.toLowerCase();
  if (haystack.contains('new ride request') ||
      haystack.contains('new booking request') ||
      haystack.contains('passenger cancelled') ||
      haystack.contains('payout')) {
    return AppNotificationAudience.driver;
  }
  if (haystack.contains('driver arriving') ||
      haystack.contains('driver matched') ||
      haystack.contains('payment required') ||
      haystack.contains('pickup updated') ||
      haystack.contains('secure seat')) {
    return AppNotificationAudience.passenger;
  }
  return AppNotificationAudience.both;
}

AppNotificationPriority _resolvePriority({
  required String kind,
  required String title,
  required String body,
  required String type,
}) {
  const urgentKinds = <String>{
    'booking_request',
    'booking_confirmed',
    'booking_payment_required',
    'booking_payment_failed',
    'booking_payment_pending',
    'ride_updated',
    'pickup_soon',
    'ride_started',
    'ride_cancelled_by_driver',
    'booking_cancelled_by_driver',
    'ride_request_created',
    'ride_request_created_nearby',
    'ride_request_created_jit',
    'ride_request_updated',
    'ride_request_assigned_driver',
    'ride_request_offer_accepted',
    'ride_request_accepted',
  };
  if (urgentKinds.contains(kind)) return AppNotificationPriority.urgent;

  final haystack = '$title $body'.toLowerCase();
  if (haystack.contains('required') ||
      haystack.contains('arriving') ||
      haystack.contains('soon') ||
      haystack.contains('cancelled') ||
      haystack.contains('changed') ||
      haystack.contains('updated') ||
      haystack.contains('accepted') ||
      haystack.contains('confirmed') ||
      haystack.contains('new ride request') ||
      haystack.contains('new booking request')) {
    return AppNotificationPriority.urgent;
  }
  if (type == 'payment' ||
      type == 'ride_update' ||
      kind != 'general' ||
      kind == 'chat_message') {
    return AppNotificationPriority.standard;
  }
  return AppNotificationPriority.low;
}
