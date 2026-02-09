import 'package:flutter/material.dart';
import '../models/category_data.dart';
import '../screens/add_expense_screen.dart';

class CategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final double? amount;

  const CategoryCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background glow effect
          Positioned(
            right: -16,
            top: -16,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 60,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          // Main content - entire area is clickable
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                final category = CategoryData.categories[title];
                if (category != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddExpenseScreen(category: category),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(24),
              highlightColor: Colors.white.withOpacity(0.05),
              splashColor: Colors.white.withOpacity(0.1),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon container - centered
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        size: 28,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Label
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFFe2e8f0),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (amount != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '₹${amount!.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: color.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
