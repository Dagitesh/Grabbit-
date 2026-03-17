import 'dart:convert';

class DealModel {
  DealModel({
    required this.id,
    required this.vendorId,
    required this.title,
    this.description,
    this.location,
    this.category,
    required this.originalPrice,
    required this.discountedPrice,
    required this.quantityAvailable,
    required this.expiryDate,
    required this.isActive,
    this.images,
    this.locationId,
    this.totalQuantity,
    this.startTime,
    this.expiryTime,
  });

  final String id;
  final String vendorId;
  final String title;
  final String? description;
  final String? location;
  final String? category;
  final double originalPrice;
  final double discountedPrice;
  final int quantityAvailable;
  final DateTime expiryDate;
  final bool isActive;
  final List<String>? images;
  final String? locationId;
  final int? totalQuantity;
  final DateTime? startTime;
  final DateTime? expiryTime;

  double get discountPercent {
    if (originalPrice <= 0) return 0;
    return 100 * (1 - discountedPrice / originalPrice);
  }

  bool get isExpired => DateTime.now().isAfter(expiryTime ?? expiryDate);
  bool get canReserve => isActive && !isExpired && quantityAvailable > 0;

  factory DealModel.fromJson(Map<String, dynamic> json) {
    List<String>? images;
    final im = json['images'];
    if (im is List) {
      images = im.map((e) => e.toString()).toList();
    } else if (im is String && im.isNotEmpty) {
      try {
        final decoded = (jsonDecode(im) as List?)?.cast<String>();
        images = decoded ?? [];
      } catch (_) {
        images = [];
      }
    }
    final expiryDateRaw = json['expiry_date'] ?? json['expiry_time'];
    final expiryDate = expiryDateRaw != null ? DateTime.parse(expiryDateRaw as String) : DateTime.now();
    final startTimeRaw = json['start_time'];
    return DealModel(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      category: json['category'] as String?,
      originalPrice: _toDouble(json['original_price']),
      discountedPrice: _toDouble(json['discounted_price'] ?? json['discount_price']),
      quantityAvailable: (json['quantity_available'] as num? ?? json['available_quantity'] as num?)?.toInt() ?? 0,
      expiryDate: expiryDate,
      isActive: json['is_active'] as bool? ?? true,
      images: images,
      locationId: json['location_id'] as String?,
      totalQuantity: (json['total_quantity'] as num?)?.toInt(),
      startTime: startTimeRaw != null ? DateTime.parse(startTimeRaw as String) : null,
      expiryTime: json['expiry_time'] != null ? DateTime.parse(json['expiry_time'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'vendor_id': vendorId,
        'title': title,
        'description': description,
        'location': location,
        'category': category,
        'original_price': originalPrice,
        'discounted_price': discountedPrice,
        'quantity_available': quantityAvailable,
        'expiry_date': expiryDate.toIso8601String(),
        'expiry_time': expiryTime?.toIso8601String(),
        'start_time': startTime?.toIso8601String(),
        'is_active': isActive,
        'images': images,
        'location_id': locationId,
        'total_quantity': totalQuantity,
      };

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
