import 'package:flutter/material.dart';

class CategoryModel {
  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    this.createdAt,
  });

  final String id;
  final String name;
  final String icon;
  final DateTime? createdAt;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? 'category',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'created_at': createdAt?.toIso8601String(),
      };

  /// Map Material icon name (snake_case) to IconData. Extend as needed.
  static IconData iconDataFromName(String name) {
    const map = {
      'bakery_dining': Icons.bakery_dining,
      'eco': Icons.eco,
      'restaurant': Icons.restaurant,
      'egg_outlined': Icons.egg_outlined,
      'dinner_dining': Icons.dinner_dining,
      'category': Icons.category,
      'local_offer': Icons.local_offer,
      'fastfood': Icons.fastfood,
      'lunch_dining': Icons.lunch_dining,
    };
    return map[name] ?? Icons.category;
  }

  IconData get iconData => iconDataFromName(icon);
}
