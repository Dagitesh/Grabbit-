import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grabbit_app/core/theme/app_colors.dart';
import 'package:grabbit_app/core/utils/currency_format.dart';
import 'package:grabbit_app/core/utils/image_url_utils.dart';
import 'package:grabbit_app/core/widgets/error_view.dart';
import 'package:grabbit_app/core/widgets/loading_overlay.dart';
import 'package:grabbit_app/features/customer/deals/providers/deal_detail_provider.dart';
import 'package:grabbit_app/features/customer/deals/presentation/screens/payment_page_screen.dart';

class DealDetailScreen extends StatefulWidget {
  const DealDetailScreen({super.key, required this.dealId});

  final String dealId;

  @override
  State<DealDetailScreen> createState() => _DealDetailScreenState();
}

class _DealDetailScreenState extends State<DealDetailScreen> {
  Timer? _timer;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DealDetailProvider>().load();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static String _formatCountdown(DateTime expiry) {
    final d = expiry.difference(DateTime.now());
    if (d.isNegative) return 'Expired';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final detailProvider = context.watch<DealDetailProvider>();

    if (detailProvider.loading && detailProvider.deal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Deal')),
        body: const LoadingOverlay(message: 'Loading...'),
      );
    }

    if (detailProvider.error != null && detailProvider.deal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Deal')),
        body: ErrorView(
          message: detailProvider.error!,
          onRetry: () => detailProvider.load(),
        ),
      );
    }

    final deal = detailProvider.deal!;
    final canReserve = deal.canReserve;

    return Scaffold(
      appBar: AppBar(
        title: Text(deal.title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (deal.images != null && deal.images!.isNotEmpty) ...[
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: deal.images!.length,
                  itemBuilder: (context, index) {
                    final url = resolveImageUrl(deal.images![index]);
                    return Padding(
                      padding: EdgeInsets.only(right: index < deal.images!.length - 1 ? 12 : 0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          url,
                          width: 280,
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 280,
                            height: 220,
                            color: AppColors.primary.withOpacity(0.12),
                            child: const Icon(Icons.broken_image, size: 48),
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 280,
                              height: 220,
                              color: AppColors.primary.withOpacity(0.12),
                              child: const Center(child: CircularProgressIndicator()),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (deal.description != null && deal.description!.isNotEmpty) ...[
              Text(
                deal.description!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
            ],
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        formatBirr(deal.originalPrice),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        formatBirr(deal.discountedPrice),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${deal.discountPercent.toStringAsFixed(0)}% off',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Quantity remaining: ${deal.quantityAvailable}'),
                  if (deal.quantityAvailable > 0) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Quantity: ', style: TextStyle(fontWeight: FontWeight.w500)),
                        IconButton.filled(
                          iconSize: 20,
                          onPressed: _quantity <= 1 ? null : () => setState(() => _quantity--),
                          icon: const Icon(Icons.remove),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('$_quantity', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ),
                        IconButton.filled(
                          iconSize: 20,
                          onPressed: _quantity >= deal.quantityAvailable ? null : () => setState(() => _quantity++),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 18, color: deal.isExpired ? Theme.of(context).colorScheme.error : AppColors.timerOrange),
                      const SizedBox(width: 6),
                      Text(
                        deal.isExpired ? 'Expired' : 'Expires in ${_formatCountdown(deal.expiryDate)}',
                        style: TextStyle(
                          color: deal.isExpired ? Theme.of(context).colorScheme.error : AppColors.timerOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: Material(
                elevation: 4,
                shadowColor: AppColors.timerOrange.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                child: FilledButton(
                  onPressed: canReserve
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PaymentPageScreen(deal: deal, quantity: _quantity),
                            ),
                          );
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.timerOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 2,
                    shadowColor: AppColors.timerOrange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(canReserve ? 'Reserve now' : (deal.isExpired ? 'Expired' : 'Out of stock')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
