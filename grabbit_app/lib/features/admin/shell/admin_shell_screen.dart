import 'package:flutter/material.dart';
import 'package:grabbit_app/core/theme/app_colors.dart';
import 'package:grabbit_app/features/admin/dashboard/presentation/screens/admin_dashboard_screen.dart';
import 'package:grabbit_app/features/admin/vendors/presentation/screens/admin_pending_vendors_screen.dart';
import 'package:grabbit_app/features/admin/categories/presentation/screens/admin_categories_screen.dart';
import 'package:grabbit_app/features/admin/settings/presentation/screens/admin_settings_screen.dart';

class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    AdminDashboardScreen(),
    AdminPendingVendorsScreen(),
    AdminCategoriesScreen(),
    AdminSettingsScreen(),
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
            icon: Icon(Icons.pending_actions_outlined, size: 26),
            activeIcon: Icon(Icons.pending_actions, size: 26),
            label: 'Vendors',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined, size: 26),
            activeIcon: Icon(Icons.category, size: 26),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined, size: 26),
            activeIcon: Icon(Icons.settings, size: 26),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
