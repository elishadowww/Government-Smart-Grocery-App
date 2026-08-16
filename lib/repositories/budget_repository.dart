import 'package:sqflite/sqflite.dart';

import '../core/constants/user_data_constants.dart';
import '../core/services/user_data_service.dart';
import '../models/budget.dart';

/// Data access for the user's shopping budget (spec §7.7 FR7) — one row per
/// Firebase uid; setting a new budget overwrites the previous one.
class BudgetRepository {
  BudgetRepository({UserDataService? service}) : _service = service ?? UserDataService();

  final UserDataService _service;

  Future<Budget?> getBudget(String uid) async {
    final db = await _service.database;
    final rows = await db.query(
      UserDataTables.budgets,
      where: '${BudgetColumns.uid} = ?',
      whereArgs: [uid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Budget.fromMap(rows.first);
  }

  Future<void> setBudget(String uid, double amount) async {
    final db = await _service.database;
    await db.insert(
      UserDataTables.budgets,
      Budget(uid: uid, amount: amount, updatedAt: DateTime.now()).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
