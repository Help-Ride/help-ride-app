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
  // add fields later when backend expands
  DriverProfile();

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile();
  }
}
