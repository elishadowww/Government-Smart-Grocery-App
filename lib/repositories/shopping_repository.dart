import 'package:sqflite/sqflite.dart';

import '../core/constants/user_data_constants.dart';
import '../core/services/user_data_service.dart';

/// A cart row's raw quantity + chosen store, before joining with product
/// and price data.
typedef CartRow = ({int quantity, String? premiseCode});

/// Data access for cart item quantities and store selection, scoped per
/// Firebase uid.
///
/// This backs the "Add to Cart" actions on the product search & detail
/// screens (spec FR5). The full Shopping List & Cost Estimator screen
/// (Module 3) is out of scope here — this repository only tracks
/// quantities and a per-item store choice so those actions do something
/// real.
class ShoppingRepository {
  ShoppingRepository({UserDataService? service})
      : _service = service ?? UserDataService();

  final UserDataService _service;

  /// Adding a product already in the cart increases its quantity instead
  /// of creating a duplicate row (spec §7.5 business rule), and records
  /// [premiseCode] as the store to buy it from — overwriting any earlier
  /// choice, since a cart line only tracks one store at a time.
  Future<void> addOrIncrementAt(
    String uid,
    String itemCode,
    String premiseCode, {
    int by = 1,
  }) async {
    final db = await _service.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        UserDataTables.shoppingListItems,
        where: '${ShoppingListItemColumns.uid} = ? AND ${ShoppingListItemColumns.itemCode} = ?',
        whereArgs: [uid, itemCode],
        limit: 1,
      );

      final newQuantity = rows.isEmpty
          ? by
          : (rows.first[ShoppingListItemColumns.quantity] as int) + by;

      await txn.insert(
        UserDataTables.shoppingListItems,
        {
          ShoppingListItemColumns.uid: uid,
          ShoppingListItemColumns.itemCode: itemCode,
          ShoppingListItemColumns.quantity: newQuantity,
          ShoppingListItemColumns.premiseCode: premiseCode,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  /// itemCode -> (quantity, chosen store). [CartRow.premiseCode] is null
  /// for rows added before store selection existed; callers should fall
  /// back to the cheapest store for those.
  Future<Map<String, CartRow>> getAll(String uid) async {
    final db = await _service.database;
    final rows = await db.query(
      UserDataTables.shoppingListItems,
      where: '${ShoppingListItemColumns.uid} = ?',
      whereArgs: [uid],
    );
    return {
      for (final r in rows)
        r[ShoppingListItemColumns.itemCode] as String: (
          quantity: r[ShoppingListItemColumns.quantity] as int,
          premiseCode: r[ShoppingListItemColumns.premiseCode] as String?,
        ),
    };
  }

  /// Sets an exact quantity, removing the row if [quantity] is 0 or less —
  /// backs the quantity stepper on the Cart screen. Leaves the chosen
  /// store untouched.
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
