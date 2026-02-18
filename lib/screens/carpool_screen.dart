import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/carpool_entry.dart';
import '../models/category_data.dart';
import '../services/database_service.dart';
import '../utils/colors.dart';

class CarpoolScreen extends StatefulWidget {
  const CarpoolScreen({super.key});

  @override
  State<CarpoolScreen> createState() => _CarpoolScreenState();
}

class _CarpoolScreenState extends State<CarpoolScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isMigratingLegacyData = false;

  @override
  void initState() {
    super.initState();
    _migrateLegacyCarpoolData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _migrateLegacyCarpoolData() async {
    setState(() {
      _isMigratingLegacyData = true;
    });

    try {
      final imported =
          await DatabaseService.migrateLegacyCarpoolDataToCategoryExpenses();
      if (mounted && imported > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported $imported legacy carpool entries.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not import legacy carpool data.')),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isMigratingLegacyData = false;
      });
    }
  }

  bool _isFeesExpense(Expense expense) {
    final rawType = (expense.carpoolType ?? '').toLowerCase();
    if (rawType == 'fees') return true;
    if (rawType == 'petrol') return false;

    final description = expense.description.toLowerCase();
    return description.contains('fee');
  }

  Future<void> _showAddEntryDialog(CarpoolEntryType type) async {
    _amountController.clear();
    _descriptionController.clear();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1e293b),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                type == CarpoolEntryType.petrol
                    ? 'Add Petrol Charge'
                    : 'Add Fees',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: '₹ ',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: type == CarpoolEntryType.petrol
                              ? AppColors.primaryGreen
                              : const Color(0xFFf87171),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Note (optional)',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: type == CarpoolEntryType.petrol
                              ? AppColors.primaryGreen
                              : const Color(0xFFf87171),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF94a3b8)),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(this.context);
                          final navigator = Navigator.of(dialogContext);
                          final amount = double.tryParse(
                            _amountController.text.trim(),
                          );
                          if (amount == null || amount <= 0) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter a valid amount greater than 0.',
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            isSubmitting = true;
                          });

                          try {
                            await DatabaseService.addExpense(
                              Expense(
                                id: '',
                                amount: amount,
                                description:
                                    _descriptionController.text.trim().isEmpty
                                        ? (type == CarpoolEntryType.petrol
                                            ? 'Petrol charge'
                                            : 'Fees')
                                        : _descriptionController.text.trim(),
                                date: DateFormat(
                                  'dd/MM/yyyy',
                                ).format(DateTime.now()),
                                category: 'Carpool',
                                carpoolType: type.name,
                              ),
                            );

                            if (!mounted || !navigator.mounted) return;
                            navigator.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  type == CarpoolEntryType.petrol
                                      ? 'Petrol charge added.'
                                      : 'Fees added and deducted from petrol.',
                                ),
                              ),
                            );
                          } catch (_) {
                            if (!mounted) return;
                            setDialogState(() {
                              isSubmitting = false;
                            });
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Failed to save entry.'),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: type == CarpoolEntryType.petrol
                        ? AppColors.primaryGreen
                        : const Color(0xFFf87171),
                    foregroundColor: Colors.white,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<Expense>>(
          stream: DatabaseService.getAllExpensesByCategory('Carpool'),
          builder: (context, snapshot) {
            final entries = snapshot.data ?? const <Expense>[];
            final balance = entries.fold<double>(
              0,
              (sum, entry) =>
                  sum + (_isFeesExpense(entry) ? -entry.amount : entry.amount),
            );

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Carpool',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track petrol charges and fees.',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                    ),
                    if (_isMigratingLegacyData) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Importing legacy carpool data...',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [
                            balance >= 0
                                ? const Color(0xFF34d399)
                                : const Color(0xFFfb7185),
                            balance >= 0
                                ? const Color(0xFF10b981)
                                : const Color(0xFFf43f5e),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Carpool Balance',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '₹${balance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            title: 'Add Petrol Charge',
                            subtitle: 'Increases balance',
                            icon: Icons.local_gas_station_outlined,
                            color: AppColors.primaryGreen,
                            onTap: () =>
                                _showAddEntryDialog(CarpoolEntryType.petrol),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionCard(
                            title: 'Add Fees',
                            subtitle: 'Subtracts balance',
                            icon: Icons.money_off_csred_outlined,
                            color: const Color(0xFFf87171),
                            onTap: () =>
                                _showAddEntryDialog(CarpoolEntryType.fees),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'History',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (entries.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Text(
                          'No carpool entries yet.',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      )
                    else
                      ...entries.map((entry) {
                        final isFees = _isFeesExpense(entry);
                        final amountColor = isFees
                            ? const Color(0xFFf87171)
                            : AppColors.primaryGreen;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: amountColor.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isFees
                                      ? Icons.money_off_csred_outlined
                                      : Icons.local_gas_station_outlined,
                                  color: amountColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.description,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      entry.date,
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${isFees ? '-' : '+'}₹${entry.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: amountColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
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
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
