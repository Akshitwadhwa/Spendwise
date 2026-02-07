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
  String _selectedDateFilter = 'All';

  late AnimationController _chartAnimationController;
  late Animation<double> _chartAnimation;
  bool _chartWasEmpty = true;

  @override
  void initState() {
    super.initState();
    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _chartAnimation = CurvedAnimation(
      parent: _chartAnimationController,
      curve: Curves.easeOutCubic,
    );
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
            color: isSelected ? Colors.black : Colors.white70,
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
          side: BorderSide(
            color: isSelected
                ? Colors.transparent
                : Colors.white.withOpacity(0.06),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
        final expenseDate = DateFormat('dd/MM/yyyy').parse(expense.date);
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
                  final category = CategoryData.categories[entry.key];
                  final total =
                      entry.value.fold(0.0, (sum, e) => sum + e.amount);

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
                  .where((cat) => cat['key'] == selectedCategory)
                  .toList();
              filteredTotal = filteredCategories.isNotEmpty
                  ? filteredCategories.first['total'] as double
                  : 0.0;
            }

            // Trigger animation when chart data appears
            if (filteredCategories.isNotEmpty && _chartWasEmpty) {
              _chartWasEmpty = false;
              _chartAnimationController.forward(from: 0.0);
            } else if (filteredCategories.isEmpty && !_chartWasEmpty) {
              _chartWasEmpty = true;
              _chartAnimationController.reverse();
            }

            // Compute summary stats
            final totalTransactions = filteredExpenses.length;
            final avgSpend =
                totalTransactions > 0 ? filteredTotal / totalTransactions : 0.0;
            final topCategory = sortedCategories.isNotEmpty
                ? sortedCategories.first['label'] as String
                : '-';

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 120.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // -- HEADER --
                    _buildHeader(allCategories),

                    const SizedBox(height: 32),

                    // -- DONUT CHART --
                    _buildDonutChart(filteredCategories, filteredTotal),

                    const SizedBox(height: 32),

                    // -- SUMMARY CARDS --
                    _buildSummaryCards(
                      totalTransactions: totalTransactions,
                      avgSpend: avgSpend,
                      topCategory: topCategory,
                    ),

                    const SizedBox(height: 28),

                    // -- CATEGORY BREAKDOWN --
                    if (filteredCategories.isNotEmpty)
                      _buildCategoryBreakdown(
                          filteredCategories, filteredTotal),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── HEADER ───────────────────────────────────────────────

  Widget _buildHeader(List<String> allCategories) {
    return Container(
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
          // Title
          const Text(
            'Spend\nAnalytics',
            style: TextStyle(
              fontSize: 28,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 16),

          // Date Filters
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
                  label: Text(
                    cat,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: Colors.white,
                  backgroundColor: const Color(0xFF1e293b),
                  onSelected: (_) {
                    setState(() {
                      selectedCategory = cat;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── DONUT CHART ──────────────────────────────────────────

  Widget _buildDonutChart(
      List<Map<String, dynamic>> categories, double total) {
    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _chartAnimation.value,
          child: Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glow behind chart
                  if (categories.isNotEmpty)
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (categories.first['color'] as Color)
                                .withOpacity(0.08),
                            blurRadius: 60,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),

                  // Chart
                  if (categories.isNotEmpty)
                    CustomPaint(
                      size: const Size(260, 260),
                      painter: DonutChartPainter(
                        categories: categories,
                        totalBalance: total,
                        animationValue: _chartAnimation.value,
                      ),
                    ),

                  // Empty state
                  if (categories.isEmpty)
                    Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF1e293b),
                          width: 28,
                        ),
                      ),
                    ),

                  // Center label
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedCategory == 'All'
                            ? 'TOTAL'
                            : selectedCategory.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '\u20B9${_formatCurrency(total)}',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── SUMMARY CARDS ────────────────────────────────────────

  Widget _buildSummaryCards({
    required int totalTransactions,
    required double avgSpend,
    required String topCategory,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              label: 'Transactions',
              value: '$totalTransactions',
              icon: Icons.receipt_long_outlined,
              color: const Color(0xFF10b981),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              label: 'Avg Spend',
              value: '\u20B9${_formatCurrency(avgSpend)}',
              icon: Icons.trending_up_rounded,
              color: const Color(0xFF6366f1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              label: 'Top Category',
              value: topCategory,
              icon: Icons.workspace_premium_outlined,
              color: const Color(0xFFf59e0b),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b).withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── CATEGORY BREAKDOWN ───────────────────────────────────

  Widget _buildCategoryBreakdown(
      List<Map<String, dynamic>> categories, double total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${categories.length} categories',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Category rows
          ...categories.map((cat) {
            final catTotal = cat['total'] as double;
            final percentage = total > 0 ? (catTotal / total * 100) : 0.0;
            final color = cat['color'] as Color;
            final icon = cat['icon'] as IconData;
            final label = cat['label'] as String;
            final expenses = cat['expenses'] as List<Expense>;

            return _buildBreakdownRow(
              label: label,
              icon: icon,
              color: color,
              amount: catTotal,
              percentage: percentage,
              count: expenses.length,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow({
    required String label,
    required IconData icon,
    required Color color,
    required double amount,
    required double percentage,
    required int count,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),

              // Label + count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count transaction${count == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Amount + percentage
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\u20B9${_formatCurrency(amount)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.06),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── DONUT CHART PAINTER ──────────────────────────────────────

class DonutChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> categories;
  final double totalBalance;
  final double animationValue;

  DonutChartPainter({
    required this.categories,
    required this.totalBalance,
    this.animationValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    const strokeWidth = 28.0;
    const gapAngle = 0.06; // gap between segments in radians

    // Background ring
    final backgroundPaint = Paint()
      ..color = const Color(0xFF1e293b)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    if (totalBalance > 0) {
      final totalGap = gapAngle * categories.length;
      final availableAngle = (2 * math.pi - totalGap) * animationValue;
      double startAngle = -math.pi / 2;

      for (int i = 0; i < categories.length; i++) {
        final item = categories[i];
        final percentage = (item['total'] as double) / totalBalance;
        final sweepAngle = availableAngle * percentage;

        // Shadow
        final shadowPaint = Paint()
          ..color = (item['color'] as Color).withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 4
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

        final rect = Rect.fromCircle(center: center, radius: radius);
        canvas.drawArc(rect, startAngle, sweepAngle, false, shadowPaint);

        // Segment
        final paint = Paint()
          ..color = item['color'] as Color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

        canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

        startAngle += sweepAngle + gapAngle;
      }
    }
  }

  @override
  bool shouldRepaint(DonutChartPainter oldDelegate) =>
      oldDelegate.categories != categories ||
      oldDelegate.totalBalance != totalBalance ||
      oldDelegate.animationValue != animationValue;
}
