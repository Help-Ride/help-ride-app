class User {
  final String id;
  final String name;
  final String email;
  final String roleDefault;
  final String? avatarUrl;
  final DriverProfile? driverProfile;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.roleDefault,
    this.avatarUrl,
    this.driverProfile,
  });

  bool get isPassenger => roleDefault == 'passenger';
  bool get isDriver => driverProfile != null;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      roleDefault: json['roleDefault'],
      avatarUrl: json['providerAvatarUrl'],
      driverProfile: json['driverProfile'] != null
          ? DriverProfile.fromJson(json['driverProfile'])
          : null,
    );
  }
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
