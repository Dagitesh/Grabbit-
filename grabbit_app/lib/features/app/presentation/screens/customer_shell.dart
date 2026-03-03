import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'explore_screen.dart';
import 'browse_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';

/// Customer-side main shell with bottom navigation: Explore, Browse, Favorites, Profile.
class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  static const int _exploreIndex = 0;
  static const int _browseIndex = 1;
  static const int _favoritesIndex = 2;
  static const int _profileIndex = 3;

  int _currentIndex = _exploreIndex;

  static const List<Widget> _screens = [
    ExploreScreen(),
    BrowseScreen(),
    FavoritesScreen(),
    ProfileScreen(),
  ];

  static const Color _unselectedColor = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        items: [
          BottomNavigationBarItem(
            icon: _NavIcon(
              icon: Icons.explore_outlined,
              isSelected: _currentIndex == _exploreIndex,
            ),
            activeIcon: _NavIcon(
              icon: Icons.explore,
              isSelected: true,
              showCircle: true,
            ),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined, color: _unselectedColor, size: 26),
            activeIcon: Icon(Icons.map_outlined, color: AppColors.primary, size: 26),
            label: 'Browse',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border, color: _unselectedColor, size: 26),
            activeIcon: Icon(Icons.favorite_border, color: AppColors.primary, size: 26),
            label: 'favorites',
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
  const _NavIcon({
    required this.icon,
    required this.isSelected,
    this.showCircle = false,
  });

  final IconData icon;
  final bool isSelected;
  final bool showCircle;

  static const Color _unselectedColor = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    if (showCircle && isSelected) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      );
    }
    return Icon(
      icon,
      size: 26,
      color: isSelected ? AppColors.primary : _unselectedColor,
    );
  }
}
