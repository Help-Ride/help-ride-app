// To parse this JSON data, do
//
//     final passengerEditProfile = passengerEditProfileFromJson(jsonString);

import 'dart:convert';

PassengerEditProfile passengerEditProfileFromJson(String str) => PassengerEditProfile.fromJson(json.decode(str));

String passengerEditProfileToJson(PassengerEditProfile data) => json.encode(data.toJson());

class PassengerEditProfile {
  String? id;
  String? name;
  String? email;
  String? phone;
  String? roleDefault;
  String? providerAvatarUrl;
  bool? emailVerified;
  DateTime? createdAt;

  PassengerEditProfile({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.roleDefault,
    this.providerAvatarUrl,
    this.emailVerified,
    this.createdAt,
  });

  factory PassengerEditProfile.fromJson(Map<String, dynamic> json) => PassengerEditProfile(
    id: json["id"],
    name: json["name"],
    email: json["email"],
    phone: json["phone"],
    roleDefault: json["roleDefault"],
    providerAvatarUrl: json["providerAvatarUrl"],
    emailVerified: json["emailVerified"],
    createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "email": email,
    "phone": phone,
    "roleDefault": roleDefault,
    "providerAvatarUrl": providerAvatarUrl,
    "emailVerified": emailVerified,
    "createdAt": createdAt?.toIso8601String(),
  };
}
