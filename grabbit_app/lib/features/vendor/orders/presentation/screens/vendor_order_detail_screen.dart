import 'package:flutter/material.dart';
import 'package:grabbit_app/core/utils/currency_format.dart';
import 'package:grabbit_app/core/theme/app_colors.dart';
import 'package:grabbit_app/features/vendor/orders/data/vendor_order_model.dart';

class VendorOrderDetailScreen extends StatelessWidget {
  const VendorOrderDetailScreen({super.key, required this.order});

  final VendorOrderModel order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _row('Deal', order.dealTitle),
          _row('Customer', order.customerName ?? '—'),
          _row('Status', order.status),
          _row('Date', _formatDate(order.createdAt)),
          if (order.discountedPrice != null) _row('Price', formatBirr(order.discountedPrice!)),
          if (order.quantity != null) _row('Quantity', '${order.quantity}'),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
