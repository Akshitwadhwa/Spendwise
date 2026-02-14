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
  String? _hoveredChartLabel;
  double? _hoveredChartAmount;
  double? _hoveredChartPercentage;

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

  List<Map<String, dynamic>> _buildPurchaseSplit(List<Expense> expenses) {
    final Map<String, Map<String, dynamic>> grouped = {};

    for (final expense in expenses) {
      final rawLabel = expense.description.trim();
      final label = rawLabel.isEmpty ? 'Unspecified' : rawLabel;
      final key = label.toLowerCase();

      grouped[key] ??= {
        'label': label,
        'total': 0.0,
        'count': 0,
      };

      grouped[key]!['total'] =
          (grouped[key]!['total'] as double) + expense.amount;
      grouped[key]!['count'] = (grouped[key]!['count'] as int) + 1;
    }

    final items = grouped.values.toList()
      ..sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));
    return items;
  }

  Color _buildSplitColor({
    required Color baseColor,
    required int index,
    required int total,
  }) {
    if (total <= 1) return baseColor;
    final hsl = HSLColor.fromColor(baseColor);
    final hueShift = ((index * 37) % 120) - 60;
    final lightnessBase = hsl.lightness + (index.isEven ? 0.12 : -0.08);
    final steppedLightness = lightnessBase + ((index / total) * 0.06);
    final lightness = steppedLightness.clamp(0.25, 0.75).toDouble();
    final saturation = (hsl.saturation + 0.06).clamp(0.35, 0.95).toDouble();
    return hsl
        .withHue((hsl.hue + hueShift + 360) % 360)
        .withLightness(lightness)
        .withSaturation(saturation)
        .toColor();
  }

  List<Map<String, dynamic>> _buildCategorySectionChartSegments(
    Map<String, dynamic> selectedCategoryData,
  ) {
    final baseColor =
        selectedCategoryData['color'] as Color? ?? AppColors.accentTeal;
    final categoryKey = selectedCategoryData['key'] as String? ?? '';
    final sections =
        _buildPurchaseSplit(selectedCategoryData['expenses'] as List<Expense>);

    return List.generate(sections.length, (index) {
      final section = sections[index];
      return {
        'key': '$categoryKey::$index',
        'label': section['label'] as String,
        'total': section['total'] as double,
        'color': _buildSplitColor(
          baseColor: baseColor,
          index: index,
          total: sections.length,
        ),
        'count': section['count'] as int,
      };
    });
  }

  String? _getTappedCategoryFromChart({
    required Offset localPosition,
    required List<Map<String, dynamic>> categories,
    required double total,
    required double animationValue,
  }) {
    if (categories.isEmpty || total <= 0) return null;

    const chartSize = Size(260, 260);
    const strokeWidth = 28.0;
    const gapAngle = 0.06;
    final center = Offset(chartSize.width / 2, chartSize.height / 2);
    final radius = chartSize.width / 2 - 20;

    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final innerRadius = radius - (strokeWidth / 2);
    final outerRadius = radius + (strokeWidth / 2);

    if (distance < innerRadius || distance > outerRadius) return null;

    final angleFromTop =
        (math.atan2(dy, dx) + (math.pi / 2) + (2 * math.pi)) % (2 * math.pi);
    final totalGap = gapAngle * categories.length;
    final availableAngle = (2 * math.pi - totalGap) * animationValue;

    double cursor = 0;
    for (final category in categories) {
      final catTotal = category['total'] as double;
      final sweep = availableAngle * (catTotal / total);
      if (angleFromTop >= cursor && angleFromTop <= cursor + sweep) {
        return category['key'] as String;
      }
      cursor += sweep + gapAngle;
    }

    return null;
  }

  void _clearHoveredChartFocus() {
    if (_hoveredChartLabel == null &&
        _hoveredChartAmount == null &&
        _hoveredChartPercentage == null) {
      return;
    }
    setState(() {
      _hoveredChartLabel = null;
      _hoveredChartAmount = null;
      _hoveredChartPercentage = null;
    });
  }

  void _updateHoveredChartLabel({
    required Offset localPosition,
    required List<Map<String, dynamic>> categories,
    required double total,
  }) {
    final hoveredKey = _getTappedCategoryFromChart(
      localPosition: localPosition,
      categories: categories,
      total: total,
      animationValue: _chartAnimation.value,
    );

    String? nextLabel;
    double? nextAmount;
    double? nextPercentage;
    if (hoveredKey != null) {
      for (final category in categories) {
        if (category['key'] == hoveredKey) {
          nextLabel = category['label'] as String?;
          nextAmount = category['total'] as double?;
          nextPercentage = (nextAmount != null && total > 0)
              ? (nextAmount / total * 100)
              : null;
          break;
        }
      }
    }

    if (_hoveredChartLabel != nextLabel ||
        _hoveredChartAmount != nextAmount ||
        _hoveredChartPercentage != nextPercentage) {
      setState(() {
        _hoveredChartLabel = nextLabel;
        _hoveredChartAmount = nextAmount;
        _hoveredChartPercentage = nextPercentage;
      });
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

            Map<String, dynamic>? selectedCategoryData;
            if (selectedCategory != 'All') {
              for (final category in sortedCategories) {
                if (category['key'] == selectedCategory) {
                  selectedCategoryData = category;
                  break;
                }
              }
            }

            final chartCategories = selectedCategory == 'All'
                ? filteredCategories
                : selectedCategoryData != null
                    ? _buildCategorySectionChartSegments(selectedCategoryData)
                    : <Map<String, dynamic>>[];
            final chartTotal = selectedCategory == 'All'
                ? filteredTotal
                : (selectedCategoryData?['total'] as double? ?? 0.0);

            // Trigger animation when chart data appears
            if (chartCategories.isNotEmpty && _chartWasEmpty) {
              _chartWasEmpty = false;
              _chartAnimationController.forward(from: 0.0);
            } else if (chartCategories.isEmpty && !_chartWasEmpty) {
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
                    _buildDonutChart(
                      categories: chartCategories,
                      total: chartTotal,
                    ),

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
                        categories: filteredCategories,
                        total: filteredTotal,
                        selectedCategoryData: selectedCategoryData,
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
                      _hoveredChartLabel = null;
                      _hoveredChartAmount = null;
                      _hoveredChartPercentage = null;
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

  Widget _buildDonutChart({
    required List<Map<String, dynamic>> categories,
    required double total,
  }) {
    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _chartAnimation.value,
          child: Center(
            child: Column(
              children: [
                GestureDetector(
                  onTapDown: (selectedCategory == 'All' || categories.isEmpty)
                      ? null
                      : (details) {
                          _updateHoveredChartLabel(
                            localPosition: details.localPosition,
                            categories: categories,
                            total: total,
                          );
                        },
                  onTapUp: (selectedCategory != 'All' || categories.isEmpty)
                      ? null
                      : (details) {
                          final tappedCategory = _getTappedCategoryFromChart(
                            localPosition: details.localPosition,
                            categories: categories,
                            total: total,
                            animationValue: _chartAnimation.value,
                          );
                          if (tappedCategory == null ||
                              tappedCategory == selectedCategory) {
                            return;
                          }
                          setState(() {
                            selectedCategory = tappedCategory;
                            _hoveredChartLabel = null;
                            _hoveredChartAmount = null;
                            _hoveredChartPercentage = null;
                          });
                        },
                  onPanUpdate: (selectedCategory == 'All' || categories.isEmpty)
                      ? null
                      : (details) {
                          _updateHoveredChartLabel(
                            localPosition: details.localPosition,
                            categories: categories,
                            total: total,
                          );
                        },
                  onPanEnd: (selectedCategory == 'All' || categories.isEmpty)
                      ? null
                      : (_) => _clearHoveredChartFocus(),
                  child: MouseRegion(
                    onHover: (event) {
                      _updateHoveredChartLabel(
                        localPosition: event.localPosition,
                        categories: categories,
                        total: total,
                      );
                    },
                    onExit: (_) {
                      _clearHoveredChartFocus();
                    },
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
                              SizedBox(
                                width: 120,
                                child: Text(
                                  (_hoveredChartLabel ??
                                          (selectedCategory == 'All'
                                              ? 'TOTAL'
                                              : selectedCategory))
                                      .toUpperCase(),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '\u20B9${_formatCurrency(_hoveredChartAmount ?? total)}',
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (_hoveredChartPercentage != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${_hoveredChartPercentage!.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (selectedCategory == 'All' && categories.length > 1) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Tap a slice to open category details',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ] else if (selectedCategory != 'All' &&
                    categories.length > 1) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Hover or drag on slices to view labels',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
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

  Widget _buildCategoryBreakdown({
    required List<Map<String, dynamic>> categories,
    required double total,
    required Map<String, dynamic>? selectedCategoryData,
  }) {
    final isDrilldown = selectedCategoryData != null;
    final purchaseSplit = isDrilldown
        ? _buildPurchaseSplit(selectedCategoryData['expenses'] as List<Expense>)
        : const <Map<String, dynamic>>[];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isDrilldown ? 'Purchase Split' : 'Breakdown',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                isDrilldown
                    ? '${purchaseSplit.length} purposes'
                    : '${categories.length} categories',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (isDrilldown) ...[
            Text(
              'Inside ${(selectedCategoryData['label'] as String)}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            ...purchaseSplit.map((item) {
              final amount = item['total'] as double;
              final percentage = total > 0 ? (amount / total * 100) : 0.0;
              return _buildBreakdownRow(
                label: item['label'] as String,
                icon: Icons.shopping_bag_outlined,
                color: selectedCategoryData['color'] as Color,
                amount: amount,
                percentage: percentage,
                count: item['count'] as int,
              );
            }),
          ] else ...[
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
