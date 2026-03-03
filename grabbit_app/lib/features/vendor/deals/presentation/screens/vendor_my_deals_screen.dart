import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grabbit_app/core/theme/app_colors.dart';
import 'package:grabbit_app/core/widgets/empty_state.dart';
import 'package:grabbit_app/core/widgets/error_view.dart';
import 'package:grabbit_app/core/widgets/loading_overlay.dart';
import 'package:grabbit_app/features/vendor/deals/providers/vendor_deal_provider.dart';
import 'package:grabbit_app/features/vendor/deals/presentation/widgets/vendor_deal_card.dart';
import 'package:grabbit_app/features/vendor/deals/presentation/screens/create_deal_screen.dart';
import 'package:grabbit_app/features/vendor/deals/presentation/screens/edit_deal_screen.dart';

class VendorMyDealsScreen extends StatelessWidget {
  const VendorMyDealsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VendorDealProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Deals'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const CreateDealScreen(),
          ),
        ).then((_) => provider.load()),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _body(BuildContext context, VendorDealProvider provider) {
    if (provider.loading && provider.deals.isEmpty) {
      return const LoadingOverlay(message: 'Loading deals...');
    }
    if (provider.error != null && provider.deals.isEmpty) {
      return ErrorView(
        message: provider.error!,
        onRetry: () => provider.load(),
      );
    }
    if (provider.deals.isEmpty) {
      return const EmptyState(
        icon: Icons.local_offer_outlined,
        title: 'No deals yet',
        subtitle: 'Tap + to create your first deal.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.deals.length,
      itemBuilder: (context, index) {
        final deal = provider.deals[index];
        return VendorDealCard(
          deal: deal,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EditDealScreen(dealId: deal.id),
            ),
          ).then((_) => provider.load()),
          onEdit: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EditDealScreen(dealId: deal.id),
            ),
          ).then((_) => provider.load()),
        );
      },
    );
  }
}
