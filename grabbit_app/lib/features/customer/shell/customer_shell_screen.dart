import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grabbit_app/core/theme/app_colors.dart';
import 'package:grabbit_app/features/customer/home/presentation/screens/customer_home_screen.dart';
import 'package:grabbit_app/features/customer/home/presentation/screens/favorites_screen.dart';
import 'package:grabbit_app/features/customer/orders/presentation/screens/my_orders_screen.dart';
import 'package:grabbit_app/features/customer/profile/presentation/screens/customer_profile_screen.dart';
import 'package:grabbit_app/features/customer/shell/customer_nav_provider.dart';

/// Customer bottom nav: Home, My Orders, Favorites, Profile.
class CustomerShellScreen extends StatefulWidget {
  const CustomerShellScreen({super.key});

  @override
  State<CustomerShellScreen> createState() => _CustomerShellScreenState();
}

class _CustomerShellScreenState extends State<CustomerShellScreen> {
  static const int _homeIndex = 0;
  static const int _ordersIndex = 1;
  static const int _favoritesIndex = 2;
  static const int _profileIndex = 3;

  int _currentIndex = _homeIndex;

  static const List<Widget> _screens = [
    CustomerHomeScreen(),
    MyOrdersScreen(),
    CustomerFavoritesScreen(),
    CustomerProfileScreen(),
  ];

  static const Color _unselectedColor = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<CustomerNavProvider>();
    if (navProvider.requestedTabIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navProvider.requestedTabIndex != null) {
          setState(() => _currentIndex = navProvider.requestedTabIndex!);
          navProvider.clearRequest();
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: _unselectedColor,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        items: [
          BottomNavigationBarItem(
            icon: _NavIcon(icon: Icons.explore_outlined, isSelected: _currentIndex == _homeIndex),
            activeIcon: _NavIcon(icon: Icons.explore, isSelected: true, showCircle: true),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined, color: _unselectedColor, size: 26),
            activeIcon: Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 26),
            label: 'My Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border, color: _unselectedColor, size: 26),
            activeIcon: Icon(Icons.favorite_border, color: AppColors.primary, size: 26),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, color: _unselectedColor, size: 26),
            activeIcon: Icon(Icons.person_outline, color: AppColors.primary, size: 26),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.icon, required this.isSelected, this.showCircle = false});

  final IconData icon;
  final bool isSelected;
  final bool showCircle;

  static const Color _unselectedColor = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    if (showCircle && isSelected) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 24),
      );
    }
    return Icon(icon, size: 26, color: isSelected ? AppColors.primary : _unselectedColor);
  }
}
