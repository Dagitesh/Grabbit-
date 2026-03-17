import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grabbit_app/core/theme/app_colors.dart';
import 'package:grabbit_app/core/widgets/empty_state.dart';
import 'package:grabbit_app/core/widgets/error_view.dart';
import 'package:grabbit_app/core/widgets/loading_overlay.dart';
import 'package:grabbit_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:grabbit_app/features/customer/home/providers/category_provider.dart';
import 'package:grabbit_app/features/customer/home/providers/deal_provider.dart';
import 'package:grabbit_app/features/customer/home/providers/favorites_provider.dart';
import 'package:grabbit_app/features/customer/home/presentation/widgets/category_filter_row.dart';
import 'package:grabbit_app/features/customer/home/presentation/widgets/deal_card.dart';
import 'package:grabbit_app/features/customer/home/presentation/widgets/price_filter_sheet.dart';
import 'package:grabbit_app/features/customer/deals/providers/deal_detail_provider.dart';
import 'package:grabbit_app/features/customer/deals/presentation/screens/deal_detail_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final userName = user?.fullName.split(' ').first ?? 'Guest';
    final dealProvider = context.watch<DealProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    final selectedLocation = dealProvider.selectedLocation ?? 'All';

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: RefreshIndicator(
        onRefresh: () => dealProvider.loadDeals(refresh: true),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 18, color: AppColors.primary),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _showLocationSheet(context, dealProvider),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                selectedLocation.toUpperCase(),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.primary),
                            ],
                          ),
                        ),
                        const Spacer(),
                        IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_greeting, $userName',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      decoration: InputDecoration(
                        hintText: 'Search for surplus food near you...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (v) => dealProvider.setFilters(search: v.isEmpty ? null : v),
                    ),
                    const SizedBox(height: 16),
                    CategoryFilterRow(
                      categories: categoryProvider.categories,
                      selectedCategoryId: dealProvider.selectedCategoryId,
                      onCategorySelected: (id) => dealProvider.setFilters(categoryId: id),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Deals',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => showModalBottomSheet(
                            context: context,
                            builder: (_) => PriceFilterSheet(
                              onApply: (min, max) {
                                dealProvider.setFilters(minPrice: min, maxPrice: max);
                                Navigator.pop(context);
                              },
                              onClear: () {
                                dealProvider.setFilters(minPrice: null, maxPrice: null);
                                Navigator.pop(context);
                              },
                            ),
                          ),
                          icon: const Icon(Icons.tune, size: 20),
                          label: const Text('Price'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (dealProvider.loading && dealProvider.deals.isEmpty)
              const SliverFillRemaining(child: LoadingOverlay(message: 'Loading deals...'))
            else if (dealProvider.error != null && dealProvider.deals.isEmpty)
              SliverFillRemaining(
                child: ErrorView(
                  message: dealProvider.error!,
                  onRetry: () => dealProvider.loadDeals(refresh: true),
                ),
              )
            else if (dealProvider.deals.isEmpty)
              const SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.local_offer_outlined,
                  title: 'No deals yet',
                  subtitle: 'Check back later for new offers.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == dealProvider.deals.length) {
                        if (dealProvider.canLoadMore && !dealProvider.loadingMore) {
                          dealProvider.loadDeals(refresh: false);
                        }
                        return dealProvider.loadingMore
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              )
                            : const SizedBox.shrink();
                      }
                      final deal = dealProvider.deals[index];
                      return DealCard(
                        deal: deal,
                        isFavorite: favoritesProvider.isFavorite(deal.id),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChangeNotifierProvider(
                              create: (_) => DealDetailProvider(deal.id),
                              child: DealDetailScreen(dealId: deal.id),
                            ),
                          ),
                        ),
                        onFavoriteTap: () => favoritesProvider.toggle(
                          deal.id,
                          title: deal.title,
                          discountedPrice: deal.discountedPrice,
                        ),
                      );
                    },
                    childCount: dealProvider.deals.length + (dealProvider.canLoadMore ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static const String _allOption = 'All';
  static const List<String> _addisAbabaSubcities = [
    'Bole',
    'Kirkos',
    'Arada',
    'Addis Ketema',
    'Lideta',
    'Gulele',
    'Yeka',
    'Lemi Kura',
    'Kolfe Keranio',
    'Nifas Silk-Lafto',
    'Akaky Kaliti',
    'Kebena',
    'Bole Bulbula',
  ];

  static void _showLocationSheet(BuildContext context, DealProvider dealProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Choose area (Addis Ababa)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              title: const Text(_allOption),
              trailing: (dealProvider.selectedLocation == null || dealProvider.selectedLocation == _allOption)
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                dealProvider.setFilters(location: null);
                Navigator.pop(context);
              },
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _addisAbabaSubcities.length,
                itemBuilder: (context, index) {
                  final loc = _addisAbabaSubcities[index];
                  return ListTile(
                    title: Text(loc),
                    trailing: dealProvider.selectedLocation == loc
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () {
                      dealProvider.setFilters(location: loc);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
