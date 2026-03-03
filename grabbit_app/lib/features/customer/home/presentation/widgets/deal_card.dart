import 'dart:async';
import 'package:flutter/material.dart';
import 'package:grabbit_app/core/theme/app_colors.dart';
import 'package:grabbit_app/core/utils/currency_format.dart';
import 'package:grabbit_app/core/utils/image_url_utils.dart';
import 'package:grabbit_app/features/customer/home/data/deal_model.dart';

class DealCard extends StatefulWidget {
  const DealCard({
    super.key,
    required this.deal,
    required this.onTap,
    required this.onFavoriteTap,
    this.isFavorite = false,
  });

  final DealModel deal;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final bool isFavorite;

  @override
  State<DealCard> createState() => _DealCardState();
}

class _DealCardState extends State<DealCard> {
  Timer? _timer;

  Widget _placeholder(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      color: AppColors.primary.withOpacity(0.12),
      child: Icon(Icons.local_offer, size: 40, color: AppColors.primary.withOpacity(0.5)),
    );
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
  void initState() {
    super.initState();
    if (widget.deal.expiryDate.isAfter(DateTime.now())) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deal = widget.deal;
    final isFavorite = widget.isFavorite;
    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: (deal.images != null && deal.images!.isNotEmpty)
                        ? Image.network(
                            resolveImageUrl(deal.images!.first),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(context),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 140,
                                color: AppColors.primary.withOpacity(0.12),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes!)
                                        : null,
                                  ),
                                ),
                              );
                            },
                          )
                        : _placeholder(context),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.grey,
                      size: 22,
                    ),
                    onPressed: widget.onFavoriteTap,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ),
                if (deal.expiryDate.isAfter(DateTime.now()))
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.timerOrange,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _formatCountdown(deal.expiryDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.deal.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${widget.deal.discountPercent.toStringAsFixed(0)}% off',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        formatBirr(widget.deal.discountedPrice),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (widget.deal.quantityAvailable <= 5 && widget.deal.quantityAvailable > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${widget.deal.quantityAvailable} left',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
