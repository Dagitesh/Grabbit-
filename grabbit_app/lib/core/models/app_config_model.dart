class AppConfigModel {
  AppConfigModel({
    this.introImageUrl,
    this.updatedAt,
  });

  final String? introImageUrl;
  final DateTime? updatedAt;

  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    return AppConfigModel(
      introImageUrl: json['intro_image_url'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'intro_image_url': introImageUrl,
        'updated_at': updatedAt?.toIso8601String(),
      };
}
