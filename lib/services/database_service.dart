import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/carpool_entry.dart';
import '../models/category_data.dart';

class DatabaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  static String? _normalizeOptionalUid(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

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

  static DocumentReference<Map<String, dynamic>> _userDoc(String userId) {
    return _db.collection('users').doc(userId);
  }

  static CollectionReference<Map<String, dynamic>> _carpoolCollection(
    String userId,
  ) {
    return _db.collection('users').doc(userId).collection('carpoolEntries');
  }

  static List<Expense> _mapExpenses(
    QuerySnapshot<Map<String, dynamic>> snapshot, {
    int? limit,
  }) {
    final docs = [...snapshot.docs];
    docs.sort((a, b) {
      final aTime = a.data()['createdAt'] as Timestamp?;
      final bTime = b.data()['createdAt'] as Timestamp?;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    final mapped = docs.map((doc) {
      final data = doc.data();
      return Expense(
        id: doc.id,
        amount: (data['amount'] as num).toDouble(),
        description: data['description'] ?? '',
        date: data['date'] ?? '',
        category: data['category'] ?? '',
        carpoolType: data['carpoolType'] as String?,
      );
    });

    if (limit == null) {
      return mapped.toList();
    }
    return mapped.take(limit).toList();
  }

  static Stream<List<Expense>> _streamExpensesByCategoryForUser({
    required String userId,
    required String categoryId,
    int? limit,
  }) {
    return _expensesCollection(userId)
        .where('category', isEqualTo: categoryId)
        .snapshots()
        .map((snapshot) => _mapExpenses(snapshot, limit: limit));
  }

  // ==================== EXPENSES ====================

  /// Add a new expense
  static Future<String> addExpense(Expense expense) async {
    final userId = _requireUserId();
    final payload = <String, dynamic>{
      'amount': expense.amount,
      'description': expense.description,
      'date': expense.date,
      'category': expense.category,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (expense.carpoolType != null) {
      payload['carpoolType'] = expense.carpoolType;
    }

    final docRef = await _expensesCollection(userId).add(payload);
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
                carpoolType: data['carpoolType'] as String?,
              );
            }).toList());
  }

  /// Get expenses by category
  static Stream<List<Expense>> getExpensesByCategory(String categoryId) {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value(const []);
    }

    return _streamExpensesByCategoryForUser(
      userId: userId,
      categoryId: categoryId,
      limit: 5,
    );
  }

  /// Get all expenses by category (no limit)
  static Stream<List<Expense>> getAllExpensesByCategory(String categoryId) {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value(const []);
    }

    return _streamExpensesByCategoryForUser(
      userId: userId,
      categoryId: categoryId,
    );
  }

  /// Update an expense
  static Future<void> updateExpense(String expenseId, Expense expense) async {
    final userId = _requireUserId();
    await _expensesCollection(userId).doc(expenseId).update({
      'amount': expense.amount,
      'description': expense.description,
      'date': expense.date,
      'category': expense.category,
      'carpoolType': expense.carpoolType ?? FieldValue.delete(),
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

  // ==================== CARPOOL ====================

  /// User profile/config values from `users/{uid}`.
  static Stream<Map<String, dynamic>> getCurrentUserSettings() {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value(const <String, dynamic>{});
    }
    return _userDoc(userId).snapshots().map(
          (snapshot) => snapshot.data() ?? const <String, dynamic>{},
        );
  }

  /// Controls whether the Wallet category grid should show Carpool.
  static Stream<bool> shouldShowCarpoolSection() {
    return getCurrentUserSettings().map(
      (settings) => settings['hideCarpoolSection'] == false,
    );
  }

  static Future<void> setCarpoolSectionHidden(bool hidden) async {
    final userId = _requireUserId();
    await _userDoc(userId).set(
      {'hideCarpoolSection': hidden},
      SetOptions(merge: true),
    );
  }

  /// UID of the account this user wants to read Carpool data from.
  static Stream<String?> getCarpoolSourceUid() {
    return getCurrentUserSettings().map(
      (settings) => _normalizeOptionalUid(settings['carpoolSourceUid']),
    );
  }

  static Future<void> setCarpoolSourceUid(String? sourceUid) async {
    final userId = _requireUserId();
    final normalized = _normalizeOptionalUid(sourceUid);
    await _userDoc(userId).set(
      {
        'carpoolSourceUid': normalized ?? FieldValue.delete(),
      },
      SetOptions(merge: true),
    );
  }

  /// UID that is allowed to read this account's Carpool expenses.
  static Stream<String?> getCarpoolSharedWithUid() {
    return getCurrentUserSettings().map(
      (settings) => _normalizeOptionalUid(settings['carpoolSharedWithUid']),
    );
  }

  static Future<void> setCarpoolSharedWithUid(String? sharedWithUid) async {
    final userId = _requireUserId();
    final normalized = _normalizeOptionalUid(sharedWithUid);
    await _userDoc(userId).set(
      {
        'carpoolSharedWithUid': normalized ?? FieldValue.delete(),
      },
      SetOptions(merge: true),
    );
  }

  /// Returns true when Carpool changes should be written to the current user.
  static Stream<bool> isCarpoolEditableForCurrentAccount() {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return Stream.value(false);
    }
    return getCarpoolSourceUid().map(
      (sourceUid) => sourceUid == null || sourceUid == currentUserId,
    );
  }

  /// Carpool expenses for current account, optionally read from a linked UID.
  static Stream<List<Expense>> getCarpoolExpensesForCurrentAccount() {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return Stream.value(const []);
    }

    return getCarpoolSourceUid().asyncExpand((sourceUid) {
      final targetUserId = sourceUid == null || sourceUid == currentUserId
          ? currentUserId
          : sourceUid;
      return _streamExpensesByCategoryForUser(
        userId: targetUserId,
        categoryId: 'Carpool',
      );
    });
  }

  /// Add a new carpool entry
  static Future<String> addCarpoolEntry(CarpoolEntry entry) async {
    final userId = _requireUserId();
    final docRef = await _carpoolCollection(userId).add({
      'type': entry.type.name,
      'amount': entry.amount,
      'description': entry.description,
      'date': entry.date,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Get all carpool entries
  static Stream<List<CarpoolEntry>> getCarpoolEntries() {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value(const []);
    }

    return _carpoolCollection(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              final rawType =
                  (data['type'] as String? ?? 'petrol').toLowerCase();
              final type = rawType == 'fees'
                  ? CarpoolEntryType.fees
                  : CarpoolEntryType.petrol;
              return CarpoolEntry(
                id: doc.id,
                type: type,
                amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
                description: data['description'] as String? ?? '',
                date: data['date'] as String? ?? '',
              );
            }).toList());
  }

  /// Carpool balance = petrol charges - fees
  static Stream<double> getCarpoolBalance() {
    return getCarpoolEntries().map((entries) {
      double total = 0;
      for (final entry in entries) {
        if (entry.type == CarpoolEntryType.petrol) {
          total += entry.amount;
        } else {
          total -= entry.amount;
        }
      }
      return total;
    });
  }

  /// One-time import from legacy `carpoolEntries` into `expenses` with category `Carpool`.
  static Future<int> migrateLegacyCarpoolDataToCategoryExpenses() async {
    final userId = _requireUserId();
    final userDoc = _db.collection('users').doc(userId);
    final userSnapshot = await userDoc.get();
    final userData = userSnapshot.data() ?? const <String, dynamic>{};

    if (userData['carpoolMigratedToCategoryExpenses'] == true) {
      return 0;
    }

    final legacyEntries = await _carpoolCollection(userId).get();
    if (legacyEntries.docs.isEmpty) {
      await userDoc.set({
        'carpoolMigratedToCategoryExpenses': true,
        'carpoolMigrationCompletedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return 0;
    }

    var importedCount = 0;
    var pendingWrites = 0;
    WriteBatch batch = _db.batch();

    for (final doc in legacyEntries.docs) {
      final data = doc.data();
      final rawType = (data['type'] as String? ?? 'petrol').toLowerCase();
      final type = rawType == 'fees' ? 'fees' : 'petrol';
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      final rawDescription = (data['description'] as String? ?? '').trim();
      final description = rawDescription.isNotEmpty
          ? rawDescription
          : (type == 'fees' ? 'Fees' : 'Petrol charge');

      final createdAt = data['createdAt'];
      final createdAtValue =
          createdAt is Timestamp ? createdAt : FieldValue.serverTimestamp();

      final expenseRef = _expensesCollection(userId).doc('carpool_${doc.id}');
      batch.set(
          expenseRef,
          {
            'amount': amount,
            'description': description,
            'date': data['date'] ?? '',
            'category': 'Carpool',
            'carpoolType': type,
            'createdAt': createdAtValue,
            'migratedFromLegacyCarpool': true,
          },
          SetOptions(merge: true));

      importedCount += 1;
      pendingWrites += 1;

      if (pendingWrites >= 400) {
        await batch.commit();
        batch = _db.batch();
        pendingWrites = 0;
      }
    }

    batch.set(
        userDoc,
        {
          'carpoolMigratedToCategoryExpenses': true,
          'carpoolMigrationCompletedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true));
    await batch.commit();

    return importedCount;
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
}
