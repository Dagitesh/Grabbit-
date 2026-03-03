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

  double get discountPercent {
    if (originalPrice <= 0) return 0;
    return 100 * (1 - discountedPrice / originalPrice);
  }

  bool get isExpired => DateTime.now().isAfter(expiryDate);
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
    return DealModel(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      category: json['category'] as String?,
      originalPrice: _toDouble(json['original_price']),
      discountedPrice: _toDouble(json['discounted_price']),
      quantityAvailable: (json['quantity_available'] as num?)?.toInt() ?? 0,
      expiryDate: DateTime.parse(json['expiry_date'] as String),
      isActive: json['is_active'] as bool? ?? true,
      images: images,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
