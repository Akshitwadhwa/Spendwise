import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/category_data.dart';
import 'carpool_screen.dart';
import '../widgets/profile_menu_item.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _exportRecords() async {
    try {
      final expenses = await DatabaseService.getExpenses().first;

      if (expenses.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No records available to export.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Show filter dialog
      if (!mounted) return;
      await _showExportFilterDialog(expenses);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not export records right now.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showExportFilterDialog(List<Expense> allExpenses) async {
    String selectedCategory = 'All';
    String selectedTimeline = 'All';

    // Get unique categories
    final Set<String> categories = {'All'};
    for (final expense in allExpenses) {
      categories.add(expense.category);
    }
    final timelineOptions = ['All', 'Last 7 days', 'Last 30 days', 'Last 3 months'];

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1e293b),
              title: const Text(
                'Filter Records',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Filter
                    Text(
                      'Category',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: DropdownButton<String>(
                        value: selectedCategory,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1e293b),
                        underline: const SizedBox(),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        items: categories.map<DropdownMenuItem<String>>((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(
                              category,
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedCategory = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Timeline Filter
                    Text(
                      'Timeline',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: DropdownButton<String>(
                        value: selectedTimeline,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1e293b),
                        underline: const SizedBox(),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        items: timelineOptions.map((timeline) {
                          return DropdownMenuItem(
                            value: timeline,
                            child: Text(
                              timeline,
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedTimeline = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF94a3b8)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _exportFilteredRecords(allExpenses, selectedCategory, selectedTimeline);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10b981),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Export'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _exportFilteredRecords(
    List<Expense> allExpenses,
    String selectedCategory,
    String selectedTimeline,
  ) async {
    try {
      // Filter by category
      var filteredExpenses = allExpenses.cast<Expense>();
      if (selectedCategory != 'All') {
        filteredExpenses = filteredExpenses
            .where((expense) => expense.category == selectedCategory)
            .toList();
      }

      // Filter by timeline
      if (selectedTimeline != 'All') {
        final now = DateTime.now();
        DateTime startDate;

        switch (selectedTimeline) {
          case 'Last 7 days':
            startDate = now.subtract(const Duration(days: 7));
            break;
          case 'Last 30 days':
            startDate = now.subtract(const Duration(days: 30));
            break;
          case 'Last 3 months':
            startDate = now.subtract(const Duration(days: 90));
            break;
          default:
            startDate = DateTime(2000);
        }

        filteredExpenses = filteredExpenses.where((expense) {
          try {
            final expenseDate = DateFormat('dd/MM/yyyy').parse(expense.date);
            return expenseDate.isAfter(startDate) ||
                expenseDate.isAtSameMomentAs(startDate);
          } catch (e) {
            return true;
          }
        }).toList();
      }

      if (filteredExpenses.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No records match the selected filters.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final excel = Excel.createExcel();
      excel.rename('Sheet1', 'Records');
      final sheet = excel['Records'];

      sheet.appendRow([
        TextCellValue('Date'),
        TextCellValue('Category'),
        TextCellValue('Description'),
        TextCellValue('Amount'),
      ]);

      for (final expense in filteredExpenses) {
        sheet.appendRow([
          TextCellValue(expense.date),
          TextCellValue(expense.category),
          TextCellValue(expense.description),
          DoubleCellValue(expense.amount),
        ]);
      }

      final bytes = excel.encode();
      if (bytes == null) {
        throw StateError('Failed to generate Excel file.');
      }

      final fileName =
          'spendwise_records_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final file = XFile.fromData(
        Uint8List.fromList(bytes),
        name: fileName,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      await Share.shareXFiles(
        [file],
        subject: 'SpendWise records export',
        text: 'Your SpendWise transaction records are ready to share.',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Export prepared successfully.'),
          backgroundColor: Color(0xFF10b981),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not export records right now.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _maskUid(String uid) {
    if (uid.length <= 8) {
      return '*' * uid.length;
    }
    final start = uid.substring(0, 4);
    final end = uid.substring(uid.length - 4);
    final middle = '*' * (uid.length - 8);
    return '$start$middle$end';
  }

  String _formatJoinedDate(User user) {
    final joinedAt = user.metadata.creationTime;
    if (joinedAt == null) return '-';
    return DateFormat('dd MMM yyyy').format(joinedAt);
  }

  String _accountTypeLabel(User user) {
    final providerIds =
        user.providerData.map((provider) => provider.providerId).toSet();

    if (providerIds.contains('google.com')) return 'Google Account';
    if (providerIds.contains('password')) return 'Password Account';
    return 'SpendWise Account';
  }

  Future<void> _signOut() async {
    await AuthService.signOut();

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _showUidDialog({
    required String title,
    required String hintText,
    required String initialValue,
    required Future<void> Function(String? value) onSave,
  }) async {
    final controller = TextEditingController(text: initialValue);

    await showDialog<void>(
      context: context,
      builder: (context) {
        var isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1e293b),
              title: Text(
                title,
                style: const TextStyle(color: Colors.white),
              ),
              content: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: const TextStyle(color: Color(0xFF64748b)),
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF10b981)),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSaving ? null : () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF94a3b8)),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setDialogState(() {
                            isSaving = true;
                          });
                          final value = controller.text.trim();
                          await onSave(value.isEmpty ? null : value);
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10b981),
                    foregroundColor: Colors.white,
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
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
    final user = AuthService.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0f172a),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0f172a),
          elevation: 0,
          title: const Text('Profile'),
        ),
        body: const Center(
          child: Text(
            'No user signed in',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final displayName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : 'SpendWise User';

    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0f172a),
        elevation: 0,
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: Colors.grey[800],
                backgroundImage:
                    user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                child: user.photoURL == null
                    ? const Icon(
                        Icons.person,
                        size: 48,
                        color: Colors.white70,
                      )
                    : null,
              ),
              const SizedBox(height: 14),
              Text(
                displayName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                user.email ?? 'No email',
                style: const TextStyle(
                  color: Color(0xFF94a3b8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _accountTypeLabel(user),
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              StreamBuilder<int>(
                stream: DatabaseService.getEntryCount(),
                builder: (context, snapshot) {
                  final totalEntries = snapshot.data ?? 0;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard('Total Entries', totalEntries.toString()),
                      _buildStatCard('Joined', _formatJoinedDate(user)),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              StreamBuilder<Map<String, dynamic>>(
                stream: DatabaseService.getCurrentUserSettings(),
                builder: (context, snapshot) {
                  final settings = snapshot.data ?? const <String, dynamic>{};
                  final hideCarpool = settings['hideCarpoolSection'] != false;
                  final carpoolSourceUid =
                      (settings['carpoolSourceUid'] as String?)?.trim() ?? '';
                  final carpoolSharedWithUid =
                      (settings['carpoolSharedWithUid'] as String?)?.trim() ??
                          '';

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[800]!),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          activeThumbColor: const Color(0xFF10b981),
                          title: const Text(
                            'Hide Carpool Section',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: const Text(
                            'Removes Carpool from Wallet categories',
                            style: TextStyle(color: Colors.grey),
                          ),
                          value: hideCarpool,
                          onChanged: (value) async {
                            await DatabaseService.setCarpoolSectionHidden(
                                value);
                          },
                        ),
                        const Divider(height: 1, color: Color(0xFF334155)),
                        ListTile(
                          leading: const Icon(
                            Icons.directions_car_outlined,
                            color: Colors.white,
                          ),
                          title: const Text(
                            'Open Carpool',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: const Text(
                            'View your linked carpool ledger',
                            style: TextStyle(color: Colors.grey),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CarpoolScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, color: Color(0xFF334155)),
                        ListTile(
                          leading: const Icon(
                            Icons.link_outlined,
                            color: Colors.white,
                          ),
                          title: const Text(
                            'Carpool Source UID',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            carpoolSourceUid.isEmpty
                                ? 'Using this account'
                                : carpoolSourceUid,
                            style: const TextStyle(color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _showUidDialog(
                            title: 'Set Carpool Source UID',
                            hintText: 'Paste source account UID',
                            initialValue: carpoolSourceUid,
                            onSave: DatabaseService.setCarpoolSourceUid,
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFF334155)),
                        ListTile(
                          leading: const Icon(
                            Icons.share_outlined,
                            color: Colors.white,
                          ),
                          title: const Text(
                            'Share Carpool With UID',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            carpoolSharedWithUid.isEmpty
                                ? 'No account linked'
                                : carpoolSharedWithUid,
                            style: const TextStyle(color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _showUidDialog(
                            title: 'Set Share With UID',
                            hintText: 'Paste allowed reader UID',
                            initialValue: carpoolSharedWithUid,
                            onSave: DatabaseService.setCarpoolSharedWithUid,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              ProfileMenuItem(
                icon: Icons.file_download_outlined,
                iconColor: const Color(0xFF10b981),
                title: 'Export Records',
                isSpecial: true,
                onTap: _exportRecords,
              ),
              _buildMenuItem(
                icon: Icons.badge_outlined,
                title: 'UID',
                subtitle: _maskUid(user.uid),
              ),
              _buildMenuItem(
                icon: Icons.logout,
                title: 'Sign Out',
                subtitle: 'Log out from this device',
                isDestructive: true,
                onTap: _signOut,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.white,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: isDestructive
          ? null
          : const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
    );
  }
}
