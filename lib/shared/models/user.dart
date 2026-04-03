class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? pendingEmail;
  final String? pendingPhone;
  final bool phoneVerified;
  final bool emailVerified;
  final String? authProvider;
  final String roleDefault;
  final String? avatarUrl;
  final List<String> authMethods;
  final String accountStatus;
  final String? stripeAccountId;
  final bool stripeOnboarded;
  final DriverProfile? driverProfile;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.pendingEmail,
    this.pendingPhone,
    required this.phoneVerified,
    required this.emailVerified,
    this.authProvider,
    required this.roleDefault,
    this.avatarUrl,
    this.authMethods = const [],
    this.accountStatus = 'active',
    this.stripeAccountId,
    this.stripeOnboarded = false,
    this.driverProfile,
  });

  bool get isPassenger => roleDefault == 'passenger';
  bool get isDriver => driverProfile != null;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      pendingEmail: json['pendingEmail']?.toString(),
      pendingPhone: json['pendingPhone']?.toString(),
      phoneVerified: _parseBool(
        json['phoneVerified'] ??
            json['isPhoneVerified'] ??
            json['phone_verified'],
      ),
      emailVerified: _parseBool(
        json['emailVerified'] ??
            json['isEmailVerified'] ??
            json['email_verified'],
      ),
      authProvider: (json['authProvider'] ?? json['provider'])
          ?.toString()
          .trim(),
      roleDefault: json['roleDefault'],
      avatarUrl: json['providerAvatarUrl'],
      authMethods: ((json['authMethods'] as List?) ?? const [])
          .map((item) => item.toString())
          .toList(),
      accountStatus: json['accountStatus']?.toString() ?? 'active',
      stripeAccountId: (json['stripeAccountId'] ?? json['stripe_account_id'])
          ?.toString(),
      stripeOnboarded: _parseBool(
        json['stripeOnboarded'] ??
            json['stripe_onboarded'] ??
            json['stripeConnected'] ??
            json['stripe_connected'],
      ),
      driverProfile: json['driverProfile'] != null
          ? DriverProfile.fromJson(json['driverProfile'])
          : null,
    );
  }
}

bool _parseBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final v = value.toLowerCase();
    return v == 'true' || v == '1';
  }
  return false;
}

class DriverProfile {
  final String id;
  final String userId;
  final String? carMake;
  final String? carModel;
  final String? carYear;
  final String? carColor;
  final String? plateNumber;
  final String? licenseNumber;
  final String? insuranceInfo;
  final bool isVerified;

  DriverProfile({
    required this.id,
    required this.userId,
    this.carMake,
    this.carModel,
    this.carYear,
    this.carColor,
    this.plateNumber,
    this.licenseNumber,
    this.insuranceInfo,
    required this.isVerified,
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      id: (json['id'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      carMake: json['carMake']?.toString(),
      carModel: json['carModel']?.toString(),
      carYear: json['carYear']?.toString(),
      carColor: json['carColor']?.toString(),
      plateNumber: json['plateNumber']?.toString(),
      licenseNumber: json['licenseNumber']?.toString(),
      insuranceInfo: json['insuranceInfo']?.toString(),
      isVerified: (json['isVerified'] ?? false) == true,
    );
  }
}
