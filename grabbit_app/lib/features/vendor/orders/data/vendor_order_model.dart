class VendorOrderModel {
  VendorOrderModel({
    required this.id,
    required this.dealId,
    required this.dealTitle,
    this.customerName,
    required this.status,
    required this.createdAt,
    this.discountedPrice,
    this.quantity,
    this.claimCode,
  });

  final String id;
  final String dealId;
  final String dealTitle;
  final String? customerName;
  final String status;
  final DateTime createdAt;
  final double? discountedPrice;
  final int? quantity;
  final String? claimCode;

  factory VendorOrderModel.fromJson(Map<String, dynamic> json) {
    return VendorOrderModel(
      id: json['id'] as String,
      dealId: json['deal_id'] as String? ?? json['dealId'] as String? ?? '',
      dealTitle: json['deal_title'] as String? ?? json['dealTitle'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? json['customerName'] as String?,
      status: json['status'] as String? ?? 'Created',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : (json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now()),
      discountedPrice: _toDouble(json['discounted_price'] ?? json['discountedPrice']),
      quantity: (json['quantity'] as num?)?.toInt(),
      claimCode: json['claim_code'] as String? ?? json['claimCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'deal_id': dealId,
        'deal_title': dealTitle,
        'customer_name': customerName,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'discounted_price': discountedPrice,
        'quantity': quantity,
        'claim_code': claimCode,
      };

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
