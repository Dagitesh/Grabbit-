class VendorProfileModel {
  VendorProfileModel({
    required this.id,
    required this.userId,
    required this.businessName,
    this.businessDescription,
    required this.phone,
    this.location,
    required this.isApproved,
  });

  final String id;
  final String userId;
  final String businessName;
  final String? businessDescription;
  final String phone;
  final String? location;
  final bool isApproved;

  factory VendorProfileModel.fromJson(Map<String, dynamic> json) {
    return VendorProfileModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      businessName: json['business_name'] as String,
      businessDescription: json['business_description'] as String?,
      phone: json['phone'] as String,
      location: json['location'] as String?,
      isApproved: json['is_approved'] as bool? ?? false,
    );
  }
}
