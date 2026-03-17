class LocationModel {
  LocationModel({
    required this.id,
    required this.vendorId,
    this.lat,
    this.long,
    this.address,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String vendorId;
  final double? lat;
  final double? long;
  final String? address;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      lat: (json['lat'] as num?)?.toDouble(),
      long: (json['long'] as num?)?.toDouble(),
      address: json['address'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'vendor_id': vendorId,
        'lat': lat,
        'long': long,
        'address': address,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}
