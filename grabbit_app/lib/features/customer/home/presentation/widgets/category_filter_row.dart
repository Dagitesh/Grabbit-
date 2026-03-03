import 'package:flutter/material.dart';
import 'package:grabbit_app/core/theme/app_colors.dart';

/// A single category option: circle icon + label. Optional "HOT" badge.
class CategoryFilterItem {
  const CategoryFilterItem({
    required this.id,
    required this.label,
    required this.icon,
    this.isHot = false,
  });

  final String id;
  final String label;
  final IconData icon;
  final bool isHot;
}

/// All categories shown in the explore filter. Id is sent to API as category filter.
const List<CategoryFilterItem> kExploreCategories = [
  CategoryFilterItem(id: 'Bakery', label: 'Bakery', icon: Icons.bakery_dining, isHot: true),
  CategoryFilterItem(id: 'Veggies', label: 'Veggies', icon: Icons.eco),
  CategoryFilterItem(id: 'Meals', label: 'Meals', icon: Icons.restaurant),
  CategoryFilterItem(id: 'Dairy', label: 'Dairy', icon: Icons.egg_outlined),
  CategoryFilterItem(id: 'Meat', label: 'Meat', icon: Icons.dinner_dining),
];

/// Horizontally scrollable row of circular category buttons with icons and labels.
/// Selected: solid green circle, white icon. Unselected: light grey circle, dark icon.
class CategoryFilterRow extends StatelessWidget {
  const CategoryFilterRow({
    super.key,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    this.categories = kExploreCategories,
  });

  final String? selectedCategoryId;
  final ValueChanged<String?> onCategorySelected;
  final List<CategoryFilterItem> categories;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final item = categories[index];
          final isSelected = selectedCategoryId == item.id;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _CategoryChip(
              item: item,
              isSelected: isSelected,
              onTap: () => onCategorySelected(isSelected ? null : item.id),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final CategoryFilterItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppColors.primary
                      : Colors.grey.shade200,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  item.icon,
                  size: 28,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
              if (item.isHot)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Text(
                      'HOT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 72,
            child: Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
