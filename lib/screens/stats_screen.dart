import 'package:flutter/material.dart';
import '../models/category_data.dart';
import '../services/database_service.dart';
import '../utils/colors.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'ANALYTICS',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textGray,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Statistics',
                style: TextStyle(
                  fontSize: 28,
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Total Spent Card
              StreamBuilder<double>(
                stream: DatabaseService.getTotalBalance(),
                builder: (context, snapshot) {
                  final total = snapshot.data ?? 0.0;
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF10b981).withOpacity(0.2),
                          const Color(0xFF10b981).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF10b981).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10b981).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_outlined,
                                color: Color(0xFF10b981),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Total Spent',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF94a3b8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '₹${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Category Breakdown
              const Text(
                'SPENDING BY CATEGORY',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textGray,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Category List
              Expanded(
                child: StreamBuilder<List<Expense>>(
                  stream: DatabaseService.getExpenses(),
                  builder: (context, snapshot) {
                    final expenses = snapshot.data ?? [];

                    if (expenses.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.pie_chart_outline,
                              size: 64,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No data to display',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Calculate totals per category
                    final Map<String, double> categoryTotals = {};
                    double grandTotal = 0;
                    for (var expense in expenses) {
                      categoryTotals[expense.category] = 
                          (categoryTotals[expense.category] ?? 0) + expense.amount;
                      grandTotal += expense.amount;
                    }

                    final sortedCategories = categoryTotals.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: sortedCategories.length,
                      itemBuilder: (context, index) {
                        final entry = sortedCategories[index];
                        final category = CategoryData.categories[entry.key];
                        final color = category?.color ?? AppColors.accentTeal;
                        final icon = category?.icon ?? Icons.category_outlined;
                        final percentage = grandTotal > 0 
                            ? (entry.value / grandTotal * 100) 
                            : 0.0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      icon,
                                      size: 20,
                                      color: color,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.key,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFFe2e8f0),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${percentage.toStringAsFixed(1)}% of total',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '₹${entry.value.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percentage / 100,
                                  backgroundColor: Colors.white.withOpacity(0.1),
                                  valueColor: AlwaysStoppedAnimation<Color>(color),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
