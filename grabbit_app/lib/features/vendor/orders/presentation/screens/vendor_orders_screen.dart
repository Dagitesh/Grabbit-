import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grabbit_app/core/theme/app_colors.dart';
import 'package:grabbit_app/core/widgets/empty_state.dart';
import 'package:grabbit_app/core/widgets/error_view.dart';
import 'package:grabbit_app/core/widgets/loading_overlay.dart';
import 'package:grabbit_app/features/vendor/orders/providers/vendor_order_provider.dart';
import 'package:grabbit_app/features/vendor/orders/presentation/screens/vendor_order_detail_screen.dart';

class VendorOrdersScreen extends StatelessWidget {
  const VendorOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VendorOrderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: provider.loading ? null : () => provider.load(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.load(),
        child: _body(context, provider),
      ),
    );
  }

  Widget _body(BuildContext context, VendorOrderProvider provider) {
    if (provider.loading && provider.orders.isEmpty) {
      return const LoadingOverlay(message: 'Loading orders...');
    }
    if (provider.error != null && provider.orders.isEmpty) {
      return ErrorView(message: provider.error!, onRetry: () => provider.load());
    }
    if (provider.orders.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No orders yet',
        subtitle: 'Orders from your deals will appear here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.orders.length,
      itemBuilder: (context, index) {
        final order = provider.orders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(order.dealTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${order.customerName ?? 'Customer'} • ${order.status} • ${_formatDate(order.createdAt)}',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => VendorOrderDetailScreen(order: order),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }
}
