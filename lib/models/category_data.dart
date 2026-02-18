import 'package:flutter/material.dart';
import '../utils/colors.dart';

class CategoryData {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final List<TagOption> tags;
  final bool isSpecial;

  const CategoryData({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.tags,
    this.isSpecial = false,
  });

  static Map<String, CategoryData> categories = {
    'Home': const CategoryData(
      id: 'Home',
      label: 'Home',
      icon: Icons.home_outlined,
      color: AppColors.homeBlue,
      tags: [
        TagOption(label: 'Coffee', icon: Icons.coffee),
        TagOption(label: 'Food', icon: Icons.local_restaurant),
        TagOption(label: 'Utilities', icon: Icons.bolt_outlined),
        TagOption(label: 'Order', icon: Icons.emoji_food_beverage_outlined),
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
        TagOption(label: 'Novarapid', icon: Icons.medication_outlined),
        TagOption(label: 'Lantus', icon: Icons.medication_outlined),
        TagOption(label: 'Sensor', icon: Icons.shield_outlined),
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
        TagOption(label: 'Auto Renew', icon: Icons.movie_outlined),
        TagOption(label: 'Travel', icon: Icons.flight_outlined),
        TagOption(label: 'Music', icon: Icons.library_music),
      ],
    ),
    'Carpool': const CategoryData(
      id: 'Carpool',
      label: 'Carpool',
      icon: Icons.directions_car_outlined,
      color: AppColors.accentTeal,
      isSpecial: true,
      tags: [
        TagOption(label: 'Petrol', icon: Icons.local_gas_station_outlined),
        TagOption(label: 'Fees', icon: Icons.payments_outlined),
        TagOption(label: 'Toll', icon: Icons.toll_outlined),
        TagOption(label: 'Parking', icon: Icons.local_parking_outlined),
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
  final String? carpoolType;

  const Expense({
    required this.id,
    required this.amount,
    required this.description,
    required this.date,
    required this.category,
    this.carpoolType,
  });
}
