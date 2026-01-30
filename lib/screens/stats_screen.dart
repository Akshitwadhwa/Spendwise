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

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  String selectedCategory = 'All';
  String _selectedDateFilter = 'This Month';
  
  late AnimationController _chartAnimationController;
  Animation<double>? _chartOpacityAnimation;
  bool _chartWasEmpty = true;

  @override
  void initState() {
    super.initState();
    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _chartOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _chartAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _chartAnimationController.dispose();
    super.dispose();
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedDateFilter == label;
    return Container(
      margin: const EdgeInsets.only(right: 8),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
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
    if (_selectedDateFilter == 'All') return expenses;

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
        final expenseDate =
            DateFormat('dd/MM/yyyy').parse(expense.date);
        return expenseDate.isAfter(startDate) ||
            expenseDate.isAtSameMomentAs(startDate);
      } catch (e) {
        return true;
      }
    }).toList();
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

            final Map<String, List<Expense>> categoryExpenses = {};
            double grandTotal = 0;

            for (var expense in filteredExpenses) {
              categoryExpenses[expense.category] ??= [];
              categoryExpenses[expense.category]!.add(expense);
              grandTotal += expense.amount;
            }

            final sortedCategories = categoryExpenses.entries
                .map((entry) {
                  final category =
                      CategoryData.categories[entry.key];
                  final total = entry.value
                      .fold(0.0, (sum, e) => sum + e.amount);

                  entry.value.sort((a, b) =>
                      b.date.compareTo(a.date));

                  return {
                    'key': entry.key,
                    'total': total,
                    'expenses': entry.value,
                    'color':
                        category?.color ?? AppColors.accentTeal,
                    'icon': category?.icon ??
                        Icons.category_outlined,
                    'label': category?.label ?? entry.key,
                  };
                })
                .where((item) =>
                    (item['total'] as double) > 0)
                .toList()
              ..sort((a, b) =>
                  (b['total'] as double)
                      .compareTo(a['total'] as double));

            final allCategories = [
              'All',
              ...CategoryData.categories.keys,
            ];

            List<Map<String, dynamic>> filteredCategories;
            double filteredTotal;

            if (selectedCategory == 'All') {
              filteredCategories = sortedCategories;
              filteredTotal = grandTotal;
            } else {
              filteredCategories = sortedCategories
                  .where((cat) =>
                      cat['key'] == selectedCategory)
                  .toList();
              filteredTotal =
                  filteredCategories.isNotEmpty
                      ? filteredCategories.first['total']
                          as double
                      : 0.0;
            }

            // Trigger animation when chart becomes visible
            if (filteredCategories.isNotEmpty && _chartWasEmpty) {
              _chartWasEmpty = false;
              _chartAnimationController.forward(from: 0.0);
            } else if (filteredCategories.isEmpty && !_chartWasEmpty) {
              _chartWasEmpty = true;
              _chartAnimationController.reverse();
            }

            return SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.only(bottom: 100.0),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    /// 🔥 FIXED HEADER SECTION
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF1e293b),
                            const Color(0xFF0f172a)
                                .withOpacity(0),
                          ],
                        ),
                        borderRadius:
                            const BorderRadius.only(
                          bottomLeft:
                              Radius.circular(40),
                          bottomRight:
                              Radius.circular(40),
                        ),
                      ),
                      padding:
                          const EdgeInsets.fromLTRB(
                              24, 48, 24, 24),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [

                          /// Title
                          const Text(
                            'Spend\nAnalytics',
                            style: TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight:
                                  FontWeight.bold,
                              height: 1.2,
                            ),
                          ),

                          const SizedBox(height: 16),

                          /// Date Filters
                          SingleChildScrollView(
                            scrollDirection:
                                Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip('All'),
                                _buildFilterChip(
                                    'Last 7 days'),
                                _buildFilterChip(
                                    'Last 10 days'),
                                _buildFilterChip(
                                    'This Month'),
                                _buildFilterChip(
                                    'Last month'),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          /// Category Chips
                          SizedBox(
                            height: 40,
                            child:
                                ListView.separated(
                              scrollDirection:
                                  Axis.horizontal,
                              itemCount:
                                  allCategories.length,
                              separatorBuilder:
                                  (_, __) =>
                                      const SizedBox(
                                          width: 10),
                              itemBuilder:
                                  (context, idx) {
                                final cat =
                                    allCategories[
                                        idx];
                                final isSelected =
                                    selectedCategory ==
                                        cat;

                                return ChoiceChip(
                                  label: Text(cat,
                                      style:
                                          TextStyle(
                                        color:
                                            isSelected
                                                ? Colors
                                                    .black
                                                : Colors
                                                    .white,
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                      )),
                                  selected:
                                      isSelected,
                                  selectedColor:
                                      Colors.white,
                                  backgroundColor:
                                      const Color(
                                          0xFF1e293b),
                                  onSelected: (_) {
                                    setState(() {
                                      selectedCategory =
                                          cat;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    /// Donut Chart
                    Center(
                      child: SizedBox(
                        width: 256,
                        height: 256,
                        child: Stack(
                          alignment:
                              Alignment.center,
                          children: [
                            if (filteredCategories
                                .isNotEmpty)
                              AnimatedOpacity(
                                opacity: _chartOpacityAnimation?.value ?? 0.0,
                                duration: const Duration(milliseconds: 800),
                                child: CustomPaint(
                                  size: const Size(
                                      256, 256),
                                  painter:
                                      DonutChartPainter(
                                    categories:
                                        filteredCategories,
                                    totalBalance:
                                        filteredTotal,
                                  ),
                                ),
                              ),
                            Column(
                              mainAxisSize:
                                  MainAxisSize.min,
                              children: [
                                Text(
                                  selectedCategory ==
                                          'All'
                                      ? 'TOTAL'
                                      : selectedCategory
                                          .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color:
                                        Colors.grey[400],
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(
                                    height: 4),
                                Text(
                                  '₹${_formatCurrency(filteredTotal)}',
                                  style:
                                      const TextStyle(
                                    fontSize: 32,
                                    fontWeight:
                                        FontWeight.bold,
                                    color:
                                        Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
}

class DonutChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> categories;
  final double totalBalance;

  DonutChartPainter({
    required this.categories,
    required this.totalBalance,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center =
        Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    const strokeWidth = 20.0;

    final backgroundPaint = Paint()
      ..color = const Color(0xFF1e293b)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius,
        backgroundPaint);

    if (totalBalance > 0) {
      double startAngle = -math.pi / 2;

      for (var item in categories) {
        final percentage =
            (item['total'] as double) /
                totalBalance;
        final sweepAngle =
            2 * math.pi * percentage;

        final paint = Paint()
          ..color = item['color'] as Color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

        final rect = Rect.fromCircle(
            center: center, radius: radius);

        canvas.drawArc(
            rect, startAngle, sweepAngle,
            false, paint);

        startAngle += sweepAngle;
      }
    }
  }

  @override
  bool shouldRepaint(
          DonutChartPainter oldDelegate) =>
      oldDelegate.categories != categories ||
      oldDelegate.totalBalance != totalBalance;
}
