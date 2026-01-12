import 'package:flutter/material.dart';
import '../utils/colors.dart';

class CategoryData {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final List<TagOption> tags;

  const CategoryData({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.tags,
  });

  static final Map<String, CategoryData> categories = {
    'Home': const CategoryData(
      id: 'Home',
      label: 'Home',
      icon: Icons.home_outlined,
      color: AppColors.homeBlue,
      tags: [
        TagOption(label: 'Rent', icon: Icons.home_outlined),
        TagOption(label: 'Groceries', icon: Icons.shopping_cart_outlined),
        TagOption(label: 'Utilities', icon: Icons.bolt_outlined),
        TagOption(label: 'Wifi', icon: Icons.wifi),
      ],
    ),
    'College': const CategoryData(
      id: 'College',
      label: 'College',
      icon: Icons.school_outlined,
      color: AppColors.collegeOrange,
      tags: [
        TagOption(label: 'Tuition', icon: Icons.school_outlined),
        TagOption(label: 'Books', icon: Icons.menu_book_outlined),
        TagOption(label: 'Food', icon: Icons.coffee_outlined),
        TagOption(label: 'Transport', icon: Icons.directions_bus_outlined),
      ],
    ),
    'Medicine': const CategoryData(
      id: 'Medicine',
      label: 'Medicine',
      icon: Icons.favorite_border,
      color: AppColors.medicinePink,
      tags: [
        TagOption(label: 'Doctor', icon: Icons.medical_services_outlined),
        TagOption(label: 'Insulin', icon: Icons.medication_outlined),
        TagOption(label: 'Insurance', icon: Icons.shield_outlined),
        TagOption(label: 'Checkup', icon: Icons.monitor_heart_outlined),
      ],
    ),
    'Lifestyle': const CategoryData(
      id: 'Lifestyle',
      label: 'Lifestyle',
      icon: Icons.spa_outlined,
      color: AppColors.lifestylePurple,
      tags: [
        TagOption(label: 'Shopping', icon: Icons.card_giftcard_outlined),
        TagOption(label: 'Movies', icon: Icons.movie_outlined),
        TagOption(label: 'Travel', icon: Icons.flight_outlined),
        TagOption(label: 'Music', icon: Icons.music_note_outlined),
      ],
    ),
  };
}

class TagOption {
  final String label;
  final IconData icon;

  const TagOption({
    required this.label,
    required this.icon,
  });
}

class Expense {
  final String id;
  final double amount;
  final String description;
  final String date;
  final String category;

  const Expense({
    required this.id,
    required this.amount,
    required this.description,
    required this.date,
    required this.category,
  });
}
