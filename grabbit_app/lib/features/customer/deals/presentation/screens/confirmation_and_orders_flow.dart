import 'package:flutter/material.dart';
import 'package:grabbit_app/core/theme/app_colors.dart';

/// Shows "Order placed" confirmation and returns true if user chose to go to My Orders.
Future<bool> showConfirmationAndGoToOrders(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Order placed'),
      content: const Text('Your reservation was successful. View it in My Orders.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Stay'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Go to My Orders'),
        ),
      ],
    ),
  );
  return result == true;
}
