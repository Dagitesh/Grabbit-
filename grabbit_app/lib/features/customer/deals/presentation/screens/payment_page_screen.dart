import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grabbit_app/core/theme/app_colors.dart';
import 'package:grabbit_app/core/utils/currency_format.dart';
import 'package:grabbit_app/features/customer/home/data/deal_model.dart';
import 'package:grabbit_app/features/customer/orders/providers/order_provider.dart';
import 'package:grabbit_app/features/customer/shell/customer_nav_provider.dart';
import 'package:grabbit_app/features/customer/deals/presentation/screens/confirmation_and_orders_flow.dart';

class PaymentPageScreen extends StatelessWidget {
  const PaymentPageScreen({super.key, required this.deal, required this.quantity});

  final DealModel deal;
  final int quantity;

  double get total => deal.discountedPrice * quantity;

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              deal.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Qty: $quantity', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  Text(
                    formatBirr(total),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Choose payment method',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _PaymentOption(
              icon: Icons.phone_android,
              label: 'Telebirr',
              onTap: orderProvider.creating
                  ? null
                  : () => _payAndConfirm(context, orderProvider),
            ),
            const SizedBox(height: 12),
            _PaymentOption(
              icon: Icons.payment,
              label: 'Chapa',
              onTap: orderProvider.creating
                  ? null
                  : () => _payAndConfirm(context, orderProvider),
            ),
            if (orderProvider.creating)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _payAndConfirm(BuildContext context, OrderProvider orderProvider) async {
    final orderId = await orderProvider.createOrder(dealId: deal.id, quantity: quantity);
    if (!context.mounted) return;
    if (orderId != null) {
      final goToOrders = await showConfirmationAndGoToOrders(context);
      if (context.mounted && goToOrders) {
        context.read<CustomerNavProvider>().requestTab(1);
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else if (context.mounted) {
        Navigator.of(context).pop();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(orderProvider.error ?? 'Failed to reserve')),
      );
    }
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      shadowColor: AppColors.timerOrange.withOpacity(0.3),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              Icon(icon, size: 28, color: AppColors.timerOrange),
              const SizedBox(width: 16),
              Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
