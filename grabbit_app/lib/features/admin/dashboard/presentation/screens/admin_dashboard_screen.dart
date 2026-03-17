import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grabbit_app/core/theme/app_colors.dart';
import 'package:grabbit_app/features/admin/dashboard/providers/admin_dashboard_provider.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.primary,
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AdminDashboardProvider>().load(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Consumer<AdminDashboardProvider>(
            builder: (context, provider, _) {
              if (provider.loading && provider.stats == null) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }
              if (provider.error != null && provider.stats == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(provider.error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => provider.load(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final s = provider.stats;
              if (s == null) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StatCard(title: 'Total Users', value: s.totalUsers.toString(), icon: Icons.people),
                  const SizedBox(height: 12),
                  _StatCard(title: 'Total Vendors', value: s.totalVendors.toString(), icon: Icons.store),
                  const SizedBox(height: 12),
                  _StatCard(
                    title: 'Pending Vendor Approvals',
                    value: s.pendingVendors.toString(),
                    icon: Icons.pending_actions,
                    highlight: s.pendingVendors > 0,
                  ),
                  const SizedBox(height: 12),
                  _StatCard(title: 'Total Deals', value: s.totalDeals.toString(), icon: Icons.local_offer),
                  const SizedBox(height: 12),
                  _StatCard(title: 'Total Orders', value: s.totalOrders.toString(), icon: Icons.receipt_long),
                  const SizedBox(height: 12),
                  _StatCard(title: 'Completed Orders', value: s.completedOrders.toString(), icon: Icons.check_circle),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value, required this.icon, this.highlight = false});

  final String title;
  final String value;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: highlight ? AppColors.primary.withOpacity(0.15) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 28, color: highlight ? AppColors.primary : Colors.grey.shade700),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700)),
                  const SizedBox(height: 4),
                  Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
