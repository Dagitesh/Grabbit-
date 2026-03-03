import 'package:flutter/material.dart';
import 'package:grabbit_app/core/theme/app_colors.dart';
import 'package:grabbit_app/features/vendor/dashboard/presentation/screens/vendor_dashboard_screen.dart';
import 'package:grabbit_app/features/vendor/deals/presentation/screens/vendor_my_deals_screen.dart';
import 'package:grabbit_app/features/vendor/orders/presentation/screens/vendor_orders_screen.dart';
import 'package:grabbit_app/features/vendor/profile/presentation/screens/vendor_profile_screen.dart';

class VendorShellScreen extends StatefulWidget {
  const VendorShellScreen({super.key});

  @override
  State<VendorShellScreen> createState() => _VendorShellScreenState();
}

class _VendorShellScreenState extends State<VendorShellScreen> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    VendorDashboardScreen(),
    VendorMyDealsScreen(),
    VendorOrdersScreen(),
    VendorProfileScreen(),
  ];

  static const Color _unselectedColor = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined, size: 26),
            activeIcon: Icon(Icons.dashboard, size: 26),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer_outlined, size: 26),
            activeIcon: Icon(Icons.local_offer, size: 26),
            label: 'My Deals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined, size: 26),
            activeIcon: Icon(Icons.receipt_long, size: 26),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 26),
            activeIcon: Icon(Icons.person, size: 26),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
