class DriverDocument {
  final String id;
  final String type;
  final String? fileName;
  final String? mimeType;
  final String? status;
  final String? createdAt;
  final String? updatedAt;

  const DriverDocument({
    required this.id,
    required this.type,
    this.fileName,
    this.mimeType,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory DriverDocument.fromJson(Map<String, dynamic> json) {
    return DriverDocument(
      id: (json['id'] ?? json['documentId'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      fileName: (json['fileName'] ?? json['filename'])?.toString(),
      mimeType: json['mimeType']?.toString(),
      status: json['status']?.toString(),
      createdAt: (json['createdAt'] ?? json['created_at'])?.toString(),
      updatedAt: (json['updatedAt'] ?? json['updated_at'])?.toString(),
    );
  }
}

class DriverDocumentPresign {
  final String uploadUrl;
  final String? documentId;
  final String? key;

  const DriverDocumentPresign({
    required this.uploadUrl,
    this.documentId,
    this.key,
  });
}
