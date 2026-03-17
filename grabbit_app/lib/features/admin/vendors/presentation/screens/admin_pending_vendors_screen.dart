import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grabbit_app/core/theme/app_colors.dart';
import 'package:grabbit_app/features/admin/vendors/providers/admin_pending_vendors_provider.dart';

class AdminPendingVendorsScreen extends StatelessWidget {
  const AdminPendingVendorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Pending Vendors'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.primary,
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AdminPendingVendorsProvider>().load(),
        child: Consumer<AdminPendingVendorsProvider>(
          builder: (context, provider, _) {
            if (provider.loading && provider.vendors.isEmpty && provider.error == null) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            if (provider.error != null && provider.vendors.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(provider.error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: () => provider.load(), child: const Text('Retry')),
                    ],
                  ),
                ),
              );
            }
            if (provider.vendors.isEmpty) {
              return const Center(child: Text('No pending vendor approvals.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.vendors.length,
              itemBuilder: (context, index) {
                final v = provider.vendors[index];
                final user = v['user'] as Map<String, dynamic>? ?? v;
                final userName = user['full_name'] as String? ?? 'Vendor';
                final email = user['email'] as String? ?? '';
                final userId = v['user_id'] as String? ?? user['id'] as String? ?? '';
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text(email, style: Theme.of(context).textTheme.bodySmall),
                        Text('Business: ${v['business_name'] ?? '-'}', style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => provider.reject(userId),
                              child: const Text('Reject'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () => provider.approve(userId),
                              child: const Text('Approve'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
