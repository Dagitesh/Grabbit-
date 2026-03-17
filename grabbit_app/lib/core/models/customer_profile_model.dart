class CustomerProfileModel {
  CustomerProfileModel({
    required this.id,
    required this.userId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CustomerProfileModel.fromJson(Map<String, dynamic> json) {
    return CustomerProfileModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}
