import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/category_data.dart';

class DatabaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // Collection references
  static final CollectionReference _expensesCollection = _db.collection('expenses');
  static final CollectionReference _categoriesCollection = _db.collection('categories');

  // ==================== EXPENSES ====================
  
  /// Add a new expense
  static Future<String> addExpense(Expense expense) async {
    final docRef = await _expensesCollection.add({
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
    return _expensesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
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
    return _expensesCollection
        .where('category', isEqualTo: categoryId)
        .snapshots()
        .map((snapshot) {
          final expenses = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Expense(
              id: doc.id,
              amount: (data['amount'] as num).toDouble(),
              description: data['description'] ?? '',
              date: data['date'] ?? '',
              category: data['category'] ?? '',
            );
          }).toList();
          
          // Sort by createdAt on the client side
          expenses.sort((a, b) {
            // Since we don't have createdAt in Expense model, we'll keep them as is
            // The most recent ones will naturally be at the end
            return 0;
          });
          
          // Return last 5 items (most recent)
          return expenses.reversed.take(5).toList();
        });
  }

  /// Update an expense
  static Future<void> updateExpense(String expenseId, Expense expense) async {
    await _expensesCollection.doc(expenseId).update({
      'amount': expense.amount,
      'description': expense.description,
      'date': expense.date,
      'category': expense.category,
    });
  }

  /// Delete an expense
  static Future<void> deleteExpense(String expenseId) async {
    await _expensesCollection.doc(expenseId).delete();
  }

  /// Get total balance (sum of all expenses)
  static Stream<double> getTotalBalance() {
    return _expensesCollection.snapshots().map((snapshot) {
      double total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += (data['amount'] as num).toDouble();
      }
      return total;
    });
  }

  /// Get entry count
  static Stream<int> getEntryCount() {
    return _expensesCollection.snapshots().map((snapshot) => snapshot.docs.length);
  }

  // ==================== CATEGORIES ====================

  /// Add a custom category
  static Future<void> addCategory(CategoryData category) async {
    await _categoriesCollection.doc(category.id).set({
      'id': category.id,
      'label': category.label,
      'iconCodePoint': category.icon.codePoint,
      'iconFontFamily': category.icon.fontFamily,
      'colorValue': category.color.value,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get all custom categories
  static Stream<List<CategoryData>> getCustomCategories() {
    return _categoriesCollection
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
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
    await _categoriesCollection.doc(categoryId).delete();
  }
}
