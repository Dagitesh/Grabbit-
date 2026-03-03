import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grabbit_app/core/utils/currency_format.dart';
import 'package:grabbit_app/core/theme/app_colors.dart';
import 'package:grabbit_app/features/customer/orders/data/order_model.dart';
import 'package:grabbit_app/features/customer/orders/providers/order_provider.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.read<OrderProvider>();
    final canCancel = order.canCancel;

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
          _row('Status', order.status),
          _row('Date', _formatDate(order.createdAt)),
          if (order.pickupAt != null) _row('Pickup by', _formatDate(order.pickupAt!)),
          if (order.discountedPrice != null) _row('Price', formatBirr(order.discountedPrice!)),
          if (order.quantity != null) _row('Quantity', '${order.quantity}'),
          if (canCancel) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Cancel order?'),
                            content: const Text('This will cancel your reservation. You can reserve again if the deal is still available.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
                              FilledButton(
                                style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Yes, cancel'),
                              ),
                            ],
                          ),
                        );
                        if (confirm != true || !context.mounted) return;
                        final ok = await orderProvider.cancelOrder(order.id);
                        if (!context.mounted) return;
                        if (ok) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order cancelled')));
                          Navigator.of(context).pop();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(orderProvider.error ?? 'Could not cancel order')),
                          );
                        }
                      },
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel order'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          ],
          if (!canCancel && order.status != 'Cancelled' && order.status != 'Completed')
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Cancellation is not allowed less than 2 hours before the pickup window.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
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
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
