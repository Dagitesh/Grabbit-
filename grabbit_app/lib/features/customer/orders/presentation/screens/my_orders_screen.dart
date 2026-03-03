import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grabbit_app/core/theme/app_colors.dart';
import 'package:grabbit_app/core/widgets/empty_state.dart';
import 'package:grabbit_app/core/widgets/error_view.dart';
import 'package:grabbit_app/core/widgets/loading_overlay.dart';
import 'package:grabbit_app/features/customer/orders/providers/order_provider.dart';
import 'package:grabbit_app/features/customer/orders/presentation/screens/order_detail_screen.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: orderProvider.loading ? null : () => orderProvider.loadOrders(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => orderProvider.loadOrders(),
        child: _body(context, orderProvider),
      ),
    );
  }

  Widget _body(BuildContext context, OrderProvider orderProvider) {
    if (orderProvider.loading && orderProvider.orders.isEmpty) {
      return const LoadingOverlay(message: 'Loading orders...');
    }
    if (orderProvider.error != null && orderProvider.orders.isEmpty) {
      return ErrorView(
        message: orderProvider.error!,
        onRetry: () => orderProvider.loadOrders(),
      );
    }
    if (orderProvider.orders.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No orders yet',
        subtitle: 'When you reserve a deal, it will appear here.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orderProvider.orders.length,
      itemBuilder: (context, index) {
        final order = orderProvider.orders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              order.dealTitle,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${order.status} • ${_formatDate(order.createdAt)}',
              style: TextStyle(
                color: _statusColor(context, order.status),
                fontSize: 13,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OrderDetailScreen(order: order),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _statusColor(BuildContext context, String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return Colors.green;
      case 'READY':
        return Colors.orange;
      case 'PAID':
        return Theme.of(context).colorScheme.primary;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }
}
