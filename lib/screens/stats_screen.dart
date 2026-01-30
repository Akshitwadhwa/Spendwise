import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category_data.dart';
import '../services/database_service.dart';
import '../utils/colors.dart';


class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String selectedCategory = 'All';
  String _selectedDateFilter = 'This Month';

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedDateFilter == label;
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label: Text(
          _getShortLabel(label),
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedDateFilter = label;
            });
          }
        },
        backgroundColor: const Color(0xFF1e293b),
        selectedColor: const Color(0xFF10b981),
        checkmarkColor: Colors.white,
        avatar: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
        elevation: isSelected ? 2 : 0,
        shadowColor: isSelected ? const Color(0xFF10b981).withOpacity(0.3) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
          side: BorderSide(
            color: isSelected ? const Color(0xFF10b981) : Colors.transparent,
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  String _getShortLabel(String label) {
    switch (label) {
      case 'Last 7 days':
        return '7 Days';
      case 'Last 10 days':
        return '10 Days';
      case 'Last month':
        return 'Last Month';
      default:
        return label;
    }
  }

  List<Expense> _filterExpensesByDate(List<Expense> expenses) {
    if (_selectedDateFilter == 'All') {
      return expenses;
    }

    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedDateFilter) {
      case 'Last 7 days':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'Last 10 days':
        startDate = now.subtract(const Duration(days: 10));
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Last month':
        startDate = DateTime(now.year, now.month - 1, 1);
        break;
      default:
        return expenses;
    }

    return expenses.where((expense) {
      try {
        final expenseDate = DateFormat('dd/MM/yyyy').parse(expense.date);
        return expenseDate.isAfter(startDate) || expenseDate.isAtSameMomentAs(startDate);
      } catch (e) {
        return true; // Include if date parsing fails
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      body: SafeArea(
        child: StreamBuilder<List<Expense>>(
          stream: DatabaseService.getExpenses(),
          builder: (context, snapshot) {
            final allExpenses = snapshot.data ?? [];
            final filteredExpenses = _filterExpensesByDate(allExpenses);

            // Group expenses by category
            final Map<String, List<Expense>> categoryExpenses = {};
            double grandTotal = 0;
            for (var expense in filteredExpenses) {
              categoryExpenses[expense.category] ??= [];
              categoryExpenses[expense.category]!.add(expense);
              grandTotal += expense.amount;
            }

            final sortedCategories = categoryExpenses.entries
                .map((entry) {
                  final category = CategoryData.categories[entry.key];
                  final total = entry.value.fold(0.0, (sum, e) => sum + e.amount);
                  // Sort expenses by date descending
                  entry.value.sort((a, b) => b.date.compareTo(a.date));
                  return {
                    'key': entry.key,
                    'total': total,
                    'expenses': entry.value,
                    'color': category?.color ?? AppColors.accentTeal,
                    'icon': category?.icon ?? Icons.category_outlined,
                    'label': category?.label ?? entry.key,
                  };
                })
                .where((item) => (item['total'] as double) > 0)
                .toList()
              ..sort((a, b) =>
                  (b['total'] as double).compareTo(a['total'] as double));

            // Build category chips
            final allCategories = [
              'All',
              ...CategoryData.categories.keys,
            ];

            // Filtered data
            List<Map<String, dynamic>> filteredCategories;
            double filteredTotal;
            if (selectedCategory == 'All') {
              filteredCategories = sortedCategories;
              filteredTotal = grandTotal;
            } else {
              filteredCategories = sortedCategories
                  .where((cat) => cat['key'] == selectedCategory)
                  .toList();
              filteredTotal = filteredCategories.isNotEmpty
                  ? filteredCategories.first['total'] as double
                  : 0.0;
            }

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with gradient background
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF1e293b),
                            const Color(0xFF0f172a).withOpacity(0),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Spend Analytics',
                                  style: TextStyle(
                                    fontSize: 28,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildFilterChip('All'),
                                    _buildFilterChip('Last 7 days'),
                                    _buildFilterChip('Last 10 days'),
                                    _buildFilterChip('This Month'),
                                    _buildFilterChip('Last month'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Category Chips
                          SizedBox(
                            height: 40,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: allCategories.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 10),
                              itemBuilder: (context, idx) {
                                final cat = allCategories[idx];
                                final isSelected = selectedCategory == cat;
                                return ChoiceChip(
                                  label: Text(cat,
                                      style: TextStyle(
                                        color: isSelected ? Colors.black : Colors.white,
                                        fontWeight: FontWeight.w600,
                                      )),
                                  selected: isSelected,
                                  selectedColor: Colors.white,
                                  backgroundColor: const Color(0xFF1e293b),
                                  onSelected: (_) {
                                    setState(() {
                                      selectedCategory = cat;
                                    });
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Donut Chart Section
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: SizedBox(
                          width: 256,
                          height: 256,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Donut Chart
                              if (filteredCategories.isNotEmpty)
                                CustomPaint(
                                  size: const Size(256, 256),
                                  painter: DonutChartPainter(
                                    categories: filteredCategories,
                                    totalBalance: filteredTotal,
                                  ),
                                ),
                              // Center Label
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    selectedCategory == 'All' ? 'TOTAL' : selectedCategory.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[400],
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${_formatCurrency(filteredTotal)}',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Details Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.only(left: 12),
                            decoration: const BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: Color(0xFF10b981),
                                  width: 4,
                                ),
                              ),
                            ),
                            child: const Text(
                              'Details',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Category List
                          filteredCategories.isEmpty
                              ? Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.05),
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'No expenses recorded yet.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: filteredCategories.map((item) {
                                    final percentage = filteredTotal > 0
                                        ? ((item['total'] as double) /
                                                filteredTotal *
                                                100)
                                            .round()
                                        : 0;
                                    final expenses = item['expenses'] as List<Expense>;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.05),
                                        ),
                                      ),
                                      child: ExpansionTile(
                                        title: Row(
                                          children: [
                                            // Icon
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: (item['color'] as Color)
                                                    .withOpacity(0.15),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                item['icon'] as IconData,
                                                size: 20,
                                                color: item['color'] as Color,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            // Category name and percentage
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item['label'] as String,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFFe2e8f0),
                                                      letterSpacing: 0.5,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        width: 8,
                                                        height: 8,
                                                        decoration: BoxDecoration(
                                                          color: item['color']
                                                              as Color,
                                                          shape: BoxShape.circle,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        '$percentage%',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey[600],
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Amount
                                            Flexible(
                                              child: Text(
                                                '₹${(item['total'] as double).toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  letterSpacing: 0.5,
                                                ),
                                                textAlign: TextAlign.right,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        children: expenses.map((expense) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            decoration: BoxDecoration(
                                              border: Border(
                                                top: BorderSide(
                                                  color: Colors.white.withOpacity(0.05),
                                                  width: 1,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        expense.description,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        expense.date,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey[400],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Text(
                                                  '₹${expense.amount.toStringAsFixed(0)}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }
}

// Custom Painter for Donut Chart
class DonutChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> categories;
  final double totalBalance;

  DonutChartPainter({
    required this.categories,
    required this.totalBalance,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    const strokeWidth = 20.0;
    final gapAngle = categories.length > 1 ? 0.02 : 0.0; // Small gap between segments

    // Draw background circle (empty track)
    final backgroundPaint = Paint()
      ..color = const Color(0xFF1e293b)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw data segments
    if (totalBalance > 0) {
      double startAngle = -math.pi / 2; // Start from top

      for (var item in categories) {
        final percentage = (item['total'] as double) / totalBalance;
        final sweepAngle = (2 * math.pi * percentage) - gapAngle;

        final paint = Paint()
          ..color = item['color'] as Color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

        final rect = Rect.fromCircle(center: center, radius: radius);
        canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

        startAngle += (2 * math.pi * percentage);
      }
    }
  }

  @override
  bool shouldRepaint(DonutChartPainter oldDelegate) {
    return oldDelegate.categories != categories ||
        oldDelegate.totalBalance != totalBalance;
  }
}
