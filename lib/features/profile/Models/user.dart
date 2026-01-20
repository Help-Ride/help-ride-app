
import '../../../shared/models/user.dart';

class EditUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String roleDefault;
  final String? avatarUrl;
  final DriverProfile? driverProfile;

  EditUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.roleDefault,
    this.avatarUrl,
    this.driverProfile,
  });

  factory EditUser.fromJson(Map<String, dynamic> json) {
    return EditUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      roleDefault: json['roleDefault'] as String? ?? 'passenger',
      avatarUrl: json['avatarUrl'] as String?,
      driverProfile: json['driverProfile'] != null
          ? DriverProfile.fromJson(json['driverProfile'])
          : null,
    );
  }

  EditUser copyWith({
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
  }) {
    return EditUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      roleDefault: roleDefault,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      driverProfile: driverProfile,
    );
  }
}
