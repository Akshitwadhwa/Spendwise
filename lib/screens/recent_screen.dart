import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category_data.dart';
import '../services/database_service.dart';
import '../utils/colors.dart';
import 'edit_expense_screen.dart';

class RecentScreen extends StatefulWidget {
  const RecentScreen({super.key});

  @override
  State<RecentScreen> createState() => _RecentScreenState();
}

class _RecentScreenState extends State<RecentScreen> {
  String _selectedDateFilter = 'All';

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
      case 'Last month':
        startDate = DateTime(now.year, now.month - 1, now.day);
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
                'RECENT',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textGray,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Transactions',
                style: TextStyle(
                  fontSize: 28,
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Date Filter
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  children: [
                    _buildFilterChip('All'),
                    _buildFilterChip('Last 7 days'),
                    _buildFilterChip('Last 10 days'),
                    _buildFilterChip('Last month'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Transactions List
              Expanded(
                child: StreamBuilder<List<Expense>>(
                  stream: DatabaseService.getExpenses(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF10b981),
                        ),
                      );
                    }

                    final allExpenses = snapshot.data ?? [];
                    final filteredExpenses = _filterExpensesByDate(allExpenses);

                    if (filteredExpenses.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No transactions yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start adding expenses to see them here',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: filteredExpenses.length,
                      itemBuilder: (context, index) {
                        final expense = filteredExpenses[index];
                        final category = CategoryData.categories[expense.category];
                        final color = category?.color ?? AppColors.accentTeal;
                        final icon = category?.icon ?? Icons.category_outlined;

                        return Dismissible(
                          key: Key(expense.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.centerRight,
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                          ),
                          onDismissed: (direction) {
                            DatabaseService.deleteExpense(expense.id);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
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
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    icon,
                                    size: 22,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        expense.description,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFFe2e8f0),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              expense.category,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: color,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '•',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            expense.date,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '-₹${expense.amount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Settings button
                                GestureDetector(
                                  onTap: () => _showOptionsBottomSheet(context, expense),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.more_vert,
                                      size: 18,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ),
                              ],
                            ),
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

  static void _showOptionsBottomSheet(BuildContext context, Expense expense) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1e293b),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Edit option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10b981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  color: Color(0xFF10b981),
                  size: 20,
                ),
              ),
              title: const Text(
                'Edit Transaction',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditExpenseScreen(expense: expense),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            // Delete option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
              ),
              title: const Text(
                'Delete Transaction',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, expense.id);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  static void _showDeleteConfirmation(BuildContext context, String expenseId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1e293b),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delete Transaction',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to delete this transaction? This action cannot be undone.',
          style: TextStyle(
            color: Color(0xFF94a3b8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[400],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              DatabaseService.deleteExpense(expenseId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transaction deleted successfully'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
