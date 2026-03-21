import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grabbit_app/core/utils/currency_format.dart' show formatBirr;
import 'package:grabbit_app/core/theme/app_colors.dart';
import 'package:grabbit_app/core/widgets/error_view.dart';
import 'package:grabbit_app/core/widgets/loading_overlay.dart';
import 'package:grabbit_app/features/vendor/dashboard/providers/vendor_dashboard_provider.dart';

class VendorDashboardScreen extends StatelessWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VendorDashboardProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
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

  Widget _body(BuildContext context, VendorDashboardProvider provider) {
    if (provider.loading && provider.dashboard == null) {
      return const LoadingOverlay(message: 'Loading dashboard...');
    }
    if (provider.error != null && provider.dashboard == null) {
      return ErrorView(
        message: provider.error!,
        onRetry: () => provider.load(),
      );
    }

    final d = provider.dashboard!;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            d.vendor.businessName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Verified vendor',
            style: TextStyle(
              color: Colors.green.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              _StatCard(
                title: 'Total Deals',
                value: '${d.totalDeals}',
                icon: Icons.local_offer,
              ),
              _StatCard(
                title: 'Active Deals',
                value: '${d.activeDeals}',
                icon: Icons.check_circle_outline,
                color: Colors.green,
              ),
              _StatCard(
                title: 'Expired Deals',
                value: '${d.expiredDeals}',
                icon: Icons.schedule,
                color: Colors.orange,
              ),
              _StatCard(
                title: 'Total Orders',
                value: '${d.totalOrders}',
                icon: Icons.receipt_long,
              ),
              if (d.revenue != null)
                _StatCard(
                  title: 'Revenue',
                  value: formatBirr(d.revenue!),
                  icon: Icons.attach_money,
                  color: AppColors.primary,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: c, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
