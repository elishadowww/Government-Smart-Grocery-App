import 'package:sqflite/sqflite.dart';

import '../core/constants/user_data_constants.dart';
import '../core/services/user_data_service.dart';

/// Data access for shopping-list item quantities, scoped per Firebase uid.
///
/// This backs the "Add to List" / "Add to Cart" actions on the product
/// search & detail screens (spec FR5). The full Shopping List & Cost
/// Estimator screen (Module 3) is out of scope here — this repository only
/// tracks quantities so those buttons do something real.
class ShoppingRepository {
  ShoppingRepository({UserDataService? service})
      : _service = service ?? UserDataService();

  final UserDataService _service;

  /// Adding a product already on the list increases its quantity instead
  /// of creating a duplicate row (spec §7.5 business rule).
  Future<void> addOrIncrement(String uid, String itemCode, {int by = 1}) async {
    final db = await _service.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        UserDataTables.shoppingListItems,
        where: '${ShoppingListItemColumns.uid} = ? AND ${ShoppingListItemColumns.itemCode} = ?',
        whereArgs: [uid, itemCode],
        limit: 1,
      );

      if (rows.isEmpty) {
        await txn.insert(UserDataTables.shoppingListItems, {
          ShoppingListItemColumns.uid: uid,
          ShoppingListItemColumns.itemCode: itemCode,
          ShoppingListItemColumns.quantity: by,
        });
        return;
      }

      final current = rows.first[ShoppingListItemColumns.quantity] as int;
      await txn.update(
        UserDataTables.shoppingListItems,
        {ShoppingListItemColumns.quantity: current + by},
        where: '${ShoppingListItemColumns.uid} = ? AND ${ShoppingListItemColumns.itemCode} = ?',
        whereArgs: [uid, itemCode],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<Map<String, int>> getAll(String uid) async {
    final db = await _service.database;
    final rows = await db.query(
      UserDataTables.shoppingListItems,
      where: '${ShoppingListItemColumns.uid} = ?',
      whereArgs: [uid],
    );
    return {
      for (final r in rows)
        r[ShoppingListItemColumns.itemCode] as String:
            r[ShoppingListItemColumns.quantity] as int,
    };
  }

  /// Sets an exact quantity, removing the row if [quantity] is 0 or less —
  /// backs the quantity stepper on the Shopping List screen.
  Future<void> setQuantity(String uid, String itemCode, int quantity) async {
    if (quantity <= 0) {
      await remove(uid, itemCode);
      return;
    }
    final db = await _service.database;
    await db.update(
      UserDataTables.shoppingListItems,
      {ShoppingListItemColumns.quantity: quantity},
      where: '${ShoppingListItemColumns.uid} = ? AND ${ShoppingListItemColumns.itemCode} = ?',
      whereArgs: [uid, itemCode],
    );
  }

  Future<void> remove(String uid, String itemCode) async {
    final db = await _service.database;
    await db.delete(
      UserDataTables.shoppingListItems,
      where: '${ShoppingListItemColumns.uid} = ? AND ${ShoppingListItemColumns.itemCode} = ?',
      whereArgs: [uid, itemCode],
    );
  }

  Future<void> clearAll(String uid) async {
    final db = await _service.database;
    await db.delete(
      UserDataTables.shoppingListItems,
      where: '${ShoppingListItemColumns.uid} = ?',
      whereArgs: [uid],
    );
  }
}
