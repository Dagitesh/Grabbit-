import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grabbit_app/core/utils/currency_format.dart';
import 'package:grabbit_app/core/theme/app_colors.dart';
import 'package:grabbit_app/core/widgets/empty_state.dart';
import 'package:grabbit_app/features/customer/home/providers/favorites_provider.dart';
import 'package:grabbit_app/features/customer/deals/providers/deal_detail_provider.dart';
import 'package:grabbit_app/features/customer/deals/presentation/screens/deal_detail_screen.dart';

class CustomerFavoritesScreen extends StatelessWidget {
  const CustomerFavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = context.watch<FavoritesProvider>();
    final items = favoritesProvider.favoriteItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: !favoritesProvider.loaded
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const EmptyState(
                  icon: Icons.favorite_border,
                  title: 'No favorites yet',
                  subtitle: 'Tap the heart on a deal to save it here.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(formatBirr(item.discountedPrice)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.favorite, color: Colors.red),
                              onPressed: () => favoritesProvider.remove(item.id),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChangeNotifierProvider(
                              create: (_) => DealDetailProvider(item.id),
                              child: DealDetailScreen(dealId: item.id),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
