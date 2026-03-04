import '../../../shared/services/api_client.dart';

enum StripeConnectStatusSummary {
  pendingVerification,
  requiresInformation,
  ready,
  unknown,
}

class StripeConnectOnboardingLink {
  const StripeConnectOnboardingLink({
    required this.onboardingUrl,
    this.expiresAt,
    required this.onboardingComplete,
    required this.payoutsEnabled,
    required this.requirementsCurrentlyDue,
  });

  final String onboardingUrl;
  final DateTime? expiresAt;
  final bool onboardingComplete;
  final bool payoutsEnabled;
  final List<String> requirementsCurrentlyDue;

  factory StripeConnectOnboardingLink.fromJson(Map<String, dynamic> json) {
    final requirements = _readStringList(
      json['requirementsCurrentlyDue'] ??
          json['requirements_currently_due'] ??
          _asMap(json['requirements'])['currentlyDue'] ??
          _asMap(json['requirements'])['currently_due'],
    );

    return StripeConnectOnboardingLink(
      onboardingUrl: _readString(
        json['onboardingUrl'] ??
            json['url'] ??
            json['accountLinkUrl'] ??
            json['account_link_url'],
      ),
      expiresAt: _readDateTime(json['expiresAt'] ?? json['expires_at']),
      onboardingComplete: _readBool(
        json['onboardingComplete'] ?? json['onboarding_complete'],
      ),
      payoutsEnabled: _readBool(
        json['payoutsEnabled'] ?? json['payouts_enabled'],
      ),
      requirementsCurrentlyDue: requirements,
    );
  }
}

class StripeConnectStatus {
  const StripeConnectStatus({
    required this.hasStripeAccount,
    required this.onboardingComplete,
    required this.payoutsEnabled,
    required this.detailsSubmitted,
    required this.requirementsCurrentlyDue,
    required this.requirementsPendingVerification,
    required this.disabledReason,
    required this.statusSummary,
    this.stripeAccountId,
  });

  const StripeConnectStatus.empty()
    : hasStripeAccount = false,
      onboardingComplete = false,
      payoutsEnabled = false,
      detailsSubmitted = false,
      requirementsCurrentlyDue = const <String>[],
      requirementsPendingVerification = const <String>[],
      disabledReason = null,
      statusSummary = StripeConnectStatusSummary.unknown,
      stripeAccountId = null;

  final bool hasStripeAccount;
  final bool onboardingComplete;
  final bool payoutsEnabled;
  final bool detailsSubmitted;
  final List<String> requirementsCurrentlyDue;
  final List<String> requirementsPendingVerification;
  final String? disabledReason;
  final StripeConnectStatusSummary statusSummary;
  final String? stripeAccountId;

  bool get payoutsReady =>
      payoutsEnabled &&
      requirementsCurrentlyDue.isEmpty &&
      requirementsPendingVerification.isEmpty &&
      (disabledReason == null || disabledReason!.trim().isEmpty);

  bool get pendingVerification =>
      statusSummary == StripeConnectStatusSummary.pendingVerification ||
      requirementsPendingVerification.isNotEmpty;

  bool get requiresInformation =>
      statusSummary == StripeConnectStatusSummary.requiresInformation ||
      requirementsCurrentlyDue.isNotEmpty;

  factory StripeConnectStatus.fromJson(Map<String, dynamic> json) {
    final stripeAccountId = _readOptionalString(
      json['stripeAccountId'] ??
          json['stripe_account_id'] ??
          _asMap(json['account'])['id'],
    );

    final requirements = _readStringList(
      json['requirementsCurrentlyDue'] ??
          json['requirements_currently_due'] ??
          _asMap(json['requirements'])['currentlyDue'] ??
          _asMap(json['requirements'])['currently_due'],
    );
    final requirementsPendingVerification = _readStringList(
      json['requirementsPendingVerification'] ??
          json['requirements_pending_verification'] ??
          _asMap(json['requirements'])['pendingVerification'] ??
          _asMap(json['requirements'])['pending_verification'],
    );
    final disabledReason = _readOptionalString(
      json['disabledReason'] ??
          json['disabled_reason'] ??
          _asMap(json['requirements'])['disabledReason'] ??
          _asMap(json['requirements'])['disabled_reason'],
    );

    final hasStripeAccount =
        _readBool(json['hasStripeAccount'] ?? json['has_stripe_account']) ||
        stripeAccountId != null;

    final onboardingComplete = _readBool(
      json['onboardingComplete'] ?? json['onboarding_complete'],
    );
    final payoutsEnabled = _readBool(
      json['payoutsEnabled'] ?? json['payouts_enabled'],
    );
    final detailsSubmitted = _readBool(
      json['detailsSubmitted'] ?? json['details_submitted'],
    );

    final statusSummary = _parseStatusSummary(
      json,
      hasStripeAccount: hasStripeAccount,
      onboardingComplete: onboardingComplete,
      payoutsEnabled: payoutsEnabled,
      detailsSubmitted: detailsSubmitted,
      requirementsCurrentlyDue: requirements,
      requirementsPendingVerification: requirementsPendingVerification,
      disabledReason: disabledReason,
    );

    return StripeConnectStatus(
      hasStripeAccount: hasStripeAccount,
      onboardingComplete: onboardingComplete,
      payoutsEnabled: payoutsEnabled,
      detailsSubmitted: detailsSubmitted,
      requirementsCurrentlyDue: requirements,
      requirementsPendingVerification: requirementsPendingVerification,
      disabledReason: disabledReason,
      statusSummary: statusSummary,
      stripeAccountId: stripeAccountId,
    );
  }
}

class StripeConnectDashboardLink {
  const StripeConnectDashboardLink({required this.url});

  final String url;

  factory StripeConnectDashboardLink.fromJson(Map<String, dynamic> json) {
    return StripeConnectDashboardLink(
      url: _readString(json['url'] ?? json['dashboardUrl']),
    );
  }
}

class StripeConnectApi {
  StripeConnectApi(this._client);
  final ApiClient _client;
  static const String _resetConfirmation = 'RESET_STRIPE_CONNECT';

  Future<StripeConnectOnboardingLink> createOnboardLink() async {
    final response = await _client.post<dynamic>('/stripe/connect/onboard');
    final body = _extractDataBody(response.data);
    final parsed = StripeConnectOnboardingLink.fromJson(body);

    if (parsed.onboardingUrl.trim().isEmpty) {
      throw Exception('Stripe onboarding URL is missing.');
    }
    return parsed;
  }

  Future<StripeConnectStatus> getConnectStatus() async {
    final response = await _client.get<dynamic>('/stripe/connect/status');
    final body = _extractDataBody(response.data);
    return StripeConnectStatus.fromJson(body);
  }

  Future<StripeConnectDashboardLink> getDashboardLink() async {
    final response = await _client.post<dynamic>(
      '/stripe/connect/dashboard-link',
    );
    final body = _extractDataBody(response.data);
    final parsed = StripeConnectDashboardLink.fromJson(body);

    if (parsed.url.trim().isEmpty) {
      throw Exception('Stripe dashboard URL is missing.');
    }
    return parsed;
  }

  Future<StripeConnectOnboardingLink> resetConnect() async {
    final response = await _client.post<dynamic>(
      '/stripe/connect/reset',
      data: const {'confirm': _resetConfirmation},
    );
    final body = _extractDataBody(response.data);
    final parsed = StripeConnectOnboardingLink.fromJson(body);

    if (parsed.onboardingUrl.trim().isEmpty) {
      throw Exception('Stripe onboarding URL is missing.');
    }
    return parsed;
  }

  Map<String, dynamic> _extractDataBody(dynamic raw) {
    final root = _asMap(raw);
    final data = _asMap(root['data']);
    return data.isNotEmpty ? data : root;
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) return value.cast<String, dynamic>();
  return const <String, dynamic>{};
}

String _readString(dynamic value) {
  return value?.toString().trim() ?? '';
}

String? _readOptionalString(dynamic value) {
  final parsed = _readString(value);
  return parsed.isEmpty ? null : parsed;
}

bool _readBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
  return false;
}

List<String> _readStringList(dynamic value) {
  if (value is! List) return const <String>[];
  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

DateTime? _readDateTime(dynamic value) {
  final raw = _readOptionalString(value);
  if (raw == null) return null;
  final parsed = DateTime.tryParse(raw);
  return parsed?.toLocal();
}

StripeConnectStatusSummary _parseStatusSummary(
  Map<String, dynamic> json, {
  required bool hasStripeAccount,
  required bool onboardingComplete,
  required bool payoutsEnabled,
  required bool detailsSubmitted,
  required List<String> requirementsCurrentlyDue,
  required List<String> requirementsPendingVerification,
  required String? disabledReason,
}) {
  final rawSummary = _readOptionalString(
    json['statusSummary'] ?? json['status_summary'],
  );
  final normalizedSummary = rawSummary
      ?.toLowerCase()
      .replaceAll('-', '_')
      .trim();

  switch (normalizedSummary) {
    case 'pending_verification':
      return StripeConnectStatusSummary.pendingVerification;
    case 'requires_information':
      return StripeConnectStatusSummary.requiresInformation;
    case 'ready':
      return StripeConnectStatusSummary.ready;
  }

  final normalizedDisabledReason = disabledReason?.toLowerCase().trim();

  if (payoutsEnabled &&
      requirementsCurrentlyDue.isEmpty &&
      requirementsPendingVerification.isEmpty &&
      (disabledReason == null || disabledReason.trim().isEmpty)) {
    return StripeConnectStatusSummary.ready;
  }
  if (requirementsCurrentlyDue.isNotEmpty) {
    return StripeConnectStatusSummary.requiresInformation;
  }
  if (requirementsPendingVerification.isNotEmpty) {
    return StripeConnectStatusSummary.pendingVerification;
  }
  if (normalizedDisabledReason != null &&
      normalizedDisabledReason.contains('pending_verification')) {
    return StripeConnectStatusSummary.pendingVerification;
  }
  if (normalizedDisabledReason != null &&
      normalizedDisabledReason.contains('requirements')) {
    return StripeConnectStatusSummary.requiresInformation;
  }
  if (hasStripeAccount && detailsSubmitted && !payoutsEnabled) {
    return StripeConnectStatusSummary.pendingVerification;
  }
  if (hasStripeAccount && !onboardingComplete) {
    return StripeConnectStatusSummary.requiresInformation;
  }
  return StripeConnectStatusSummary.unknown;
}
