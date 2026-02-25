import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../utils/colors.dart';
import '../widgets/category_card.dart';
import '../widgets/new_category_card.dart';
import '../widgets/bottom_navbar.dart';
import '../models/category_data.dart';
import '../services/database_service.dart';
import 'add_category_screen.dart';
import 'profile_screen.dart';
import 'quick_add_expense_screen.dart';

enum _BalanceView { all, month }

class WalletScreen extends StatefulWidget {
  final Function(TabType)? onTabChange;

  const WalletScreen({super.key, this.onTabChange});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  _BalanceView _balanceView = _BalanceView.all;

  @override
  void initState() {
    super.initState();
    _migrateLegacyCarpoolData();
  }

  Future<void> _migrateLegacyCarpoolData() async {
    try {
      await DatabaseService.migrateLegacyCarpoolDataToCategoryExpenses();
    } catch (_) {}
  }

  void _addCustomCategory(CategoryData category) {
    DatabaseService.addCategory(category);
    CategoryData.categories[category.id] = category;
  }

  void _openAddCategoryScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCategoryScreen(
          onCategoryCreated: _addCustomCategory,
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getUserFirstName() {
    final displayName = FirebaseAuth.instance.currentUser?.displayName;
    if (displayName == null || displayName.isEmpty) return '';
    return displayName.split(' ').first;
  }

  String? _getUserPhotoUrl() {
    return FirebaseAuth.instance.currentUser?.photoURL;
  }

  bool _isCarpoolExpense(Expense expense) {
    return expense.category.toLowerCase() == 'carpool';
  }

  bool _isSensorExpense(Expense expense) {
    return expense.description.toLowerCase().contains('sensor');
  }

  double _getMonthTotal(List<Expense> expenses) {
    final now = DateTime.now();
    double total = 0;
    for (var expense in expenses) {
      if (_isCarpoolExpense(expense)) continue;
      try {
        final date = DateFormat('dd/MM/yyyy').parse(expense.date);
        if (date.month == now.month && date.year == now.year) {
          total += expense.amount;
        }
      } catch (_) {}
    }
    return total;
  }

  double _getTodayTotal(List<Expense> expenses) {
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    double total = 0;
    for (var expense in expenses) {
      if (_isCarpoolExpense(expense)) continue;
      if (expense.date == today) {
        total += expense.amount;
      }
    }
    return total;
  }

  bool _isExpenseInCurrentMonth(Expense expense) {
    try {
      final now = DateTime.now();
      final date = DateFormat('dd/MM/yyyy').parse(expense.date);
      return date.month == now.month && date.year == now.year;
    } catch (_) {
      return false;
    }
  }

  Map<String, double> _getCategoryTotals(List<Expense> expenses) {
    final Map<String, double> totals = {};
    for (var expense in expenses) {
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
    }
    return totals;
  }

  void _showBalanceSplitPopup(BuildContext context) {
    final isMonthView = _balanceView == _BalanceView.month;
    showDialog(
      context: context,
      builder: (context) => StreamBuilder<List<Expense>>(
        stream: DatabaseService.getExpenses(),
        builder: (context, snapshot) {
          final expenses = snapshot.data ?? [];
          var totalSpendExpenses =
              expenses.where((expense) => !_isCarpoolExpense(expense)).toList();
          if (isMonthView) {
            totalSpendExpenses = totalSpendExpenses
                .where(_isExpenseInCurrentMonth)
                .toList();
          }

          final Map<String, double> categoryTotals = {};
          double grandTotal = 0;
          for (var expense in totalSpendExpenses) {
            categoryTotals[expense.category] =
                (categoryTotals[expense.category] ?? 0) + expense.amount;
            grandTotal += expense.amount;
          }

          final sortedCategories = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1e293b),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isMonthView ? 'This Month\'s Split' : 'Spending Split',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF10b981).withOpacity(0.2),
                          const Color(0xFF10b981).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF10b981).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          isMonthView ? 'This Month\'s Spending' : 'Total Spending',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${grandTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10b981),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (sortedCategories.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No expenses yet',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: sortedCategories.length,
                        itemBuilder: (context, index) {
                          final entry = sortedCategories[index];
                          final category = CategoryData.categories[entry.key];
                          final color = category?.color ?? AppColors.accentTeal;
                          final icon =
                              category?.icon ?? Icons.category_outlined;
                          final percentage = grandTotal > 0
                              ? (entry.value / grandTotal * 100)
                              : 0.0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    icon,
                                    size: 18,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.key,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: percentage / 100,
                                          backgroundColor:
                                              Colors.white.withOpacity(0.1),
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  color),
                                          minHeight: 4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${entry.value.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      '${percentage.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _getGreeting();
    final firstName = _getUserFirstName();
    final photoUrl = _getUserPhotoUrl();

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<Expense>>(
          stream: DatabaseService.getExpenses(),
          builder: (context, expenseSnapshot) {
            final allExpenses = expenseSnapshot.data ?? [];
            final selectedViewExpenses = _balanceView == _BalanceView.month
                ? allExpenses.where(_isExpenseInCurrentMonth).toList()
                : allExpenses;
            final categoryTotals = _getCategoryTotals(selectedViewExpenses);
            final monthTotal = _getMonthTotal(allExpenses);
            final todayTotal = _getTodayTotal(allExpenses);
            final nonSensorExpenses = allExpenses
                .where(
                  (expense) =>
                      !_isSensorExpense(expense) && !_isCarpoolExpense(expense),
                )
                .toList();
            final selectedViewNonSensorExpenses =
                _balanceView == _BalanceView.month
                    ? nonSensorExpenses.where(_isExpenseInCurrentMonth).toList()
                    : nonSensorExpenses;
            final displayedBalance = selectedViewNonSensorExpenses.fold<double>(
              0,
              (sum, expense) => sum + expense.amount,
            );
            final displayedBalanceLabel =
                _balanceView == _BalanceView.month ? 'This month' : 'All time';

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$greeting${firstName.isNotEmpty ? ',' : ''}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                firstName.isNotEmpty
                                    ? firstName
                                    : 'Your Wallet',
                                style: const TextStyle(
                                  fontSize: 26,
                                  color: AppColors.textWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const QuickAddExpenseScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF10b981).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF10b981)
                                        .withOpacity(0.35),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      size: 14,
                                      color: Color(0xFF10b981),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'AI Add',
                                      style: TextStyle(
                                        color: Color(0xFF10b981),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ProfileScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        AppColors.primaryGreen.withOpacity(0.4),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryGreen
                                          .withOpacity(0.15),
                                      blurRadius: 12,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: photoUrl != null
                                      ? Image.network(
                                          photoUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _buildAvatarFallback(firstName),
                                        )
                                      : _buildAvatarFallback(firstName),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Balance Toggle ──
                    Row(
                      children: [
                        Expanded(
                          child: _buildBalanceToggleOption(
                            label: 'All',
                            isSelected: _balanceView == _BalanceView.all,
                            onTap: () {
                              if (_balanceView == _BalanceView.all) return;
                              setState(() {
                                _balanceView = _BalanceView.all;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildBalanceToggleOption(
                            label: 'This Month',
                            isSelected: _balanceView == _BalanceView.month,
                            onTap: () {
                              if (_balanceView == _BalanceView.month) return;
                              setState(() {
                                _balanceView = _BalanceView.month;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Balance Card ──
                    GestureDetector(
                      onTap: () => _showBalanceSplitPopup(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF3dd598),
                              Color(0xFF25a06a),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGreen.withOpacity(0.3),
                              blurRadius: 24,
                              spreadRadius: 0,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Decorative circles
                            Positioned(
                              right: -30,
                              top: -30,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.08),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 30,
                              bottom: -40,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.06),
                                ),
                              ),
                            ),
                            Positioned(
                              left: -20,
                              bottom: -20,
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.05),
                                ),
                              ),
                            ),
                            // Card content
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total Balance',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.pie_chart_outline,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${allExpenses.length} entries',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '₹${displayedBalance.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                // Current period indicator
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '$displayedBalanceLabel view',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── Quick Stats Row ──
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.today_rounded,
                            label: 'Today',
                            value: '₹${todayTotal.toStringAsFixed(0)}',
                            color: const Color(0xFF60a5fa),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.date_range_rounded,
                            label: 'This Month',
                            value: '₹${monthTotal.toStringAsFixed(0)}',
                            color: const Color(0xFFf59e0b),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.receipt_long_rounded,
                            label: 'Entries',
                            value: '${allExpenses.length}',
                            color: const Color(0xFFa78bfa),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Categories Section ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Categories',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.textWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: _openAddCategoryScreen,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primaryGreen.withOpacity(0.3),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add,
                                  color: AppColors.primaryGreen,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Add New',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Category Cards Grid
                    StreamBuilder<List<CategoryData>>(
                      stream: DatabaseService.getCustomCategories(),
                      builder: (context, snapshot) {
                        final customCategories = snapshot.data ?? [];

                        for (var category in customCategories) {
                          CategoryData.categories[category.id] = category;
                        }

                        return StreamBuilder<bool>(
                          stream: DatabaseService.shouldShowCarpoolSection(),
                          builder: (context, showCarpoolSnapshot) {
                            final showCarpool =
                                showCarpoolSnapshot.data ?? false;

                            final categoryCards = <Widget>[
                              CategoryCard(
                                title: 'Home',
                                icon: Icons.home_outlined,
                                color: AppColors.homeBlue,
                                amount: categoryTotals['Home'],
                              ),
                              CategoryCard(
                                title: 'College',
                                icon: Icons.school_outlined,
                                color: AppColors.collegeOrange,
                                amount: categoryTotals['College'],
                              ),
                              CategoryCard(
                                title: 'Medicine',
                                icon: Icons.favorite_border,
                                color: AppColors.medicinePink,
                                amount: categoryTotals['Medicine'],
                              ),
                              CategoryCard(
                                title: 'Lifestyle',
                                icon: Icons.spa_outlined,
                                color: AppColors.lifestylePurple,
                                amount: categoryTotals['Lifestyle'],
                              ),
                              if (showCarpool)
                                CategoryCard(
                                  title: 'Carpool',
                                  icon: Icons.directions_car_outlined,
                                  color: AppColors.accentTeal,
                                  amount: categoryTotals['Carpool'],
                                ),
                              ...customCategories
                                  .map((category) => CategoryCard(
                                        title: category.label,
                                        icon: category.icon,
                                        color: category.color,
                                        amount: categoryTotals[category.label],
                                      )),
                              NewCategoryCard(onTap: _openAddCategoryScreen),
                            ];

                            return LayoutBuilder(
                              builder: (context, constraints) {
                                const spacing = 14.0;
                                final maxWidth = constraints.maxWidth;
                                final crossAxisCount = maxWidth >= 900
                                    ? 4
                                    : maxWidth >= 620
                                        ? 3
                                        : 2;

                                final itemWidth = (maxWidth -
                                        (spacing * (crossAxisCount - 1))) /
                                    crossAxisCount;
                                final textScale =
                                    MediaQuery.textScalerOf(context).scale(1.0);
                                final mainAxisExtent = (itemWidth *
                                        (1.02 + ((textScale - 1.0) * 0.2)))
                                    .clamp(150.0, 210.0)
                                    .toDouble();

                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: categoryCards.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: spacing,
                                    mainAxisSpacing: spacing,
                                    mainAxisExtent: mainAxisExtent,
                                  ),
                                  itemBuilder: (context, index) =>
                                      categoryCards[index],
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // ── Recent Activity Preview ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Activity',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.textWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            widget.onTabChange?.call(TabType.recent);
                          },
                          child: Text(
                            'See all',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.primaryGreen.withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (allExpenses.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 36,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No transactions yet',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...allExpenses.take(3).map((expense) {
                        final category =
                            CategoryData.categories[expense.category];
                        final color = category?.color ?? AppColors.accentTeal;
                        final icon = category?.icon ?? Icons.category_outlined;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                          child: Row(
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
                                      expense.description,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFFe2e8f0),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Text(
                                          expense.category,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: color,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '•',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 10,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          expense.date,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '-₹${expense.amount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 120),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBalanceToggleOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryGreen.withOpacity(0.2)
                : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryGreen.withOpacity(0.5)
                  : Colors.white.withOpacity(0.1),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.primaryGreen : Colors.grey[400],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
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

  Widget _buildAvatarFallback(String name) {
    return Container(
      color: AppColors.primaryGreen.withOpacity(0.2),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: AppColors.primaryGreen,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
