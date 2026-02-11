class SupportAppConfig {
  const SupportAppConfig({
    required this.id,
    required this.maintenanceMode,
    required this.maintenanceMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final bool maintenanceMode;
  final String? maintenanceMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SupportAppConfig.fromJson(Map<String, dynamic> json) {
    return SupportAppConfig(
      id: (json['id'] ?? '').toString(),
      maintenanceMode: json['maintenanceMode'] == true,
      maintenanceMessage: json['maintenanceMessage']?.toString(),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }
}

DateTime _parseDate(dynamic value) {
  if (value is DateTime) return value;
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  return parsed ?? DateTime.fromMillisecondsSinceEpoch(0);
}
