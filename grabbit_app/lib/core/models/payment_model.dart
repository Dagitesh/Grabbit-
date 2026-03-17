class PaymentModel {
  PaymentModel({
    required this.id,
    required this.orderId,
    required this.gatewayProvider,
    required this.transactionReference,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String orderId;
  final String gatewayProvider;
  final String transactionReference;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      gatewayProvider: json['gateway_provider'] as String,
      transactionReference: json['transaction_reference'] as String,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_id': orderId,
        'gateway_provider': gatewayProvider,
        'transaction_reference': transactionReference,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}
