class OrderModel {
  OrderModel({
    required this.id,
    required this.dealId,
    required this.dealTitle,
    required this.status,
    required this.createdAt,
    this.discountedPrice,
    this.quantity,
    this.pickupAt,
  });

  final String id;
  final String dealId;
  final String dealTitle;
  final String status; // Created, Paid, Ready, Completed, Cancelled
  final DateTime createdAt;
  final double? discountedPrice;
  final int? quantity;
  final DateTime? pickupAt;

  /// Can cancel only if more than 2 hours before pickup and not already completed/cancelled.
  bool get canCancel {
    if (status == 'Cancelled' || status == 'Completed') return false;
    final p = pickupAt;
    if (p == null) return true;
    return DateTime.now().isBefore(p.subtract(const Duration(hours: 2)));
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      dealId: json['deal_id'] as String? ?? json['dealId'] as String? ?? '',
      dealTitle: json['deal_title'] as String? ?? json['dealTitle'] as String? ?? '',
      status: json['status'] as String? ?? 'Created',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now()),
      discountedPrice: _toDouble(json['discounted_price'] ?? json['discountedPrice']),
      quantity: (json['quantity'] as num?)?.toInt(),
      pickupAt: json['pickup_at'] != null ? DateTime.parse(json['pickup_at'] as String) : null,
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final d = double.tryParse(v.toString());
    return d;
  }
}
