import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/category_data.dart';

class LegacyMigrationResult {
  final int migratedExpenses;
  final int skippedExpenses;
  final int migratedCategories;
  final int skippedCategories;

  const LegacyMigrationResult({
    required this.migratedExpenses,
    required this.skippedExpenses,
    required this.migratedCategories,
    required this.skippedCategories,
  });

  int get totalMigrated => migratedExpenses + migratedCategories;
}

class DatabaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  static String _requireUserId() {
    final userId = _currentUserId;
    if (userId == null) {
      throw StateError('User must be logged in to access data.');
    }
    return userId;
  }

  static CollectionReference<Map<String, dynamic>> _expensesCollection(
    String userId,
  ) {
    return _db.collection('users').doc(userId).collection('expenses');
  }

  static CollectionReference<Map<String, dynamic>> _categoriesCollection(
    String userId,
  ) {
    return _db.collection('users').doc(userId).collection('categories');
  }

  // ==================== EXPENSES ====================

  /// Add a new expense
  static Future<String> addExpense(Expense expense) async {
    final userId = _requireUserId();
    final docRef = await _expensesCollection(userId).add({
      'amount': expense.amount,
      'description': expense.description,
      'date': expense.date,
      'category': expense.category,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Get all expenses
  static Stream<List<Expense>> getExpenses() {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value(const []);
    }

    return _expensesCollection(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return Expense(
                id: doc.id,
                amount: (data['amount'] as num).toDouble(),
                description: data['description'] ?? '',
                date: data['date'] ?? '',
                category: data['category'] ?? '',
              );
            }).toList());
  }

  /// Get expenses by category
  static Stream<List<Expense>> getExpensesByCategory(String categoryId) {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value(const []);
    }

    return _expensesCollection(userId)
        .where('category', isEqualTo: categoryId)
        .snapshots()
        .map((snapshot) {
          final docs = [...snapshot.docs];
          docs.sort((a, b) {
            final aTime = a.data()['createdAt'] as Timestamp?;
            final bTime = b.data()['createdAt'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });

          return docs.take(5).map((doc) {
            final data = doc.data();
            return Expense(
              id: doc.id,
              amount: (data['amount'] as num).toDouble(),
              description: data['description'] ?? '',
              date: data['date'] ?? '',
              category: data['category'] ?? '',
            );
          }).toList();
        });
  }

  /// Update an expense
  static Future<void> updateExpense(String expenseId, Expense expense) async {
    final userId = _requireUserId();
    await _expensesCollection(userId).doc(expenseId).update({
      'amount': expense.amount,
      'description': expense.description,
      'date': expense.date,
      'category': expense.category,
    });
  }

  /// Delete an expense
  static Future<void> deleteExpense(String expenseId) async {
    final userId = _requireUserId();
    await _expensesCollection(userId).doc(expenseId).delete();
  }

  /// Get total balance (sum of all expenses, excluding Sensor)
  static Stream<double> getTotalBalance() {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value(0.0);
    }

    return _expensesCollection(userId).snapshots().map((snapshot) {
      double total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final description = data['description'] as String? ?? '';

        // Exclude Sensor expenses from total balance
        if (!description.toLowerCase().contains('sensor')) {
          total += (data['amount'] as num).toDouble();
        }
      }
      return total;
    });
  }

  /// Get entry count
  static Stream<int> getEntryCount() {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value(0);
    }

    return _expensesCollection(userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ==================== CATEGORIES ====================

  /// Add a custom category
  static Future<void> addCategory(CategoryData category) async {
    final userId = _requireUserId();
    await _categoriesCollection(userId).doc(category.id).set({
      'id': category.id,
      'label': category.label,
      'iconCodePoint': category.icon.codePoint,
      'iconFontFamily': category.icon.fontFamily,
      'colorValue': category.color.toARGB32(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get all custom categories
  static Stream<List<CategoryData>> getCustomCategories() {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value(const []);
    }

    return _categoriesCollection(userId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return CategoryData(
                id: data['id'] ?? doc.id,
                label: data['label'] ?? '',
                icon: IconData(
                  data['iconCodePoint'] ?? Icons.category.codePoint,
                  fontFamily: data['iconFontFamily'] ?? 'MaterialIcons',
                ),
                color: Color(data['colorValue'] ?? 0xFF5b7db1),
                tags: [], // Custom categories have no predefined tags
              );
            }).toList());
  }

  /// Delete a category
  static Future<void> deleteCategory(String categoryId) async {
    final userId = _requireUserId();
    await _categoriesCollection(userId).doc(categoryId).delete();
  }

  // ==================== LEGACY MIGRATION ====================

  /// Copies old global data (`expenses`, `categories`) into user-scoped paths.
  /// Existing user documents with the same IDs are skipped.
  static Future<LegacyMigrationResult> migrateLegacyDataToCurrentUser() async {
    final userId = _requireUserId();

    final legacyExpensesSnapshot = await _db.collection('expenses').get();
    final legacyCategoriesSnapshot = await _db.collection('categories').get();

    final currentUserExpensesSnapshot = await _expensesCollection(userId).get();
    final currentUserCategoriesSnapshot =
        await _categoriesCollection(userId).get();

    final existingExpenseIds = currentUserExpensesSnapshot.docs
        .map((doc) => doc.id)
        .toSet();
    final existingCategoryIds = currentUserCategoriesSnapshot.docs
        .map((doc) => doc.id)
        .toSet();

    int migratedExpenses = 0;
    int skippedExpenses = 0;
    int migratedCategories = 0;
    int skippedCategories = 0;
    int pendingOperations = 0;
    WriteBatch batch = _db.batch();

    Future<void> commitBatchIfNeeded({bool force = false}) async {
      if (!force && pendingOperations < 400) {
        return;
      }
      if (pendingOperations == 0) {
        return;
      }
      await batch.commit();
      batch = _db.batch();
      pendingOperations = 0;
    }

    for (final doc in legacyExpensesSnapshot.docs) {
      if (existingExpenseIds.contains(doc.id)) {
        skippedExpenses++;
        continue;
      }

      batch.set(
        _expensesCollection(userId).doc(doc.id),
        {
          ...doc.data(),
          'migratedFromLegacy': true,
          'migratedAt': FieldValue.serverTimestamp(),
        },
      );
      pendingOperations++;
      migratedExpenses++;
      await commitBatchIfNeeded();
    }

    for (final doc in legacyCategoriesSnapshot.docs) {
      if (existingCategoryIds.contains(doc.id)) {
        skippedCategories++;
        continue;
      }

      batch.set(
        _categoriesCollection(userId).doc(doc.id),
        {
          ...doc.data(),
          'migratedFromLegacy': true,
          'migratedAt': FieldValue.serverTimestamp(),
        },
      );
      pendingOperations++;
      migratedCategories++;
      await commitBatchIfNeeded();
    }

    await commitBatchIfNeeded(force: true);

    return LegacyMigrationResult(
      migratedExpenses: migratedExpenses,
      skippedExpenses: skippedExpenses,
      migratedCategories: migratedCategories,
      skippedCategories: skippedCategories,
    );
  }
}
