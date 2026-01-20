class PassengerEditProfileRequest {
  final String name;
  final String phone;
  final String providerAvatarUrl;

  PassengerEditProfileRequest({
    required this.name,
    required this.phone,
    required this.providerAvatarUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "phone": phone,
      "providerAvatarUrl": providerAvatarUrl,
    };
  }
}
