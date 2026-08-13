import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../constants/user_data_constants.dart';

/// Opens the on-device database for per-user app state (saved products,
/// recent searches/products, in-app notifications, shopping list quantities).
///
/// Unlike [DatabaseService] (the read-only bundled PriceCatcher catalog),
/// this database starts empty and is written to at runtime, so it lives in
/// its own file and is created (not copied from assets) on first use.
class UserDataService {
  UserDataService();

  static const String _fileName = 'app_data.db';

  static Future<Database>? _openFuture;

  Future<Database> get database {
    return _openFuture ??= _open();
  }

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), _fileName);
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ${UserDataTables.savedProducts} (
            ${SavedProductColumns.uid} TEXT NOT NULL,
            ${SavedProductColumns.itemCode} TEXT NOT NULL,
            ${SavedProductColumns.savedAt} TEXT NOT NULL,
            ${SavedProductColumns.trackedPrice} REAL,
            PRIMARY KEY (${SavedProductColumns.uid}, ${SavedProductColumns.itemCode})
          )
        ''');

        await db.execute('''
          CREATE TABLE ${UserDataTables.recentSearches} (
            ${RecentSearchColumns.uid} TEXT NOT NULL,
            ${RecentSearchColumns.term} TEXT NOT NULL,
            ${RecentSearchColumns.searchedAt} TEXT NOT NULL,
            PRIMARY KEY (${RecentSearchColumns.uid}, ${RecentSearchColumns.term})
          )
        ''');

        await db.execute('''
          CREATE TABLE ${UserDataTables.recentProducts} (
            ${RecentProductColumns.uid} TEXT NOT NULL,
            ${RecentProductColumns.itemCode} TEXT NOT NULL,
            ${RecentProductColumns.viewedAt} TEXT NOT NULL,
            PRIMARY KEY (${RecentProductColumns.uid}, ${RecentProductColumns.itemCode})
          )
        ''');

        await db.execute('''
          CREATE TABLE ${UserDataTables.notifications} (
            ${NotificationColumns.id} INTEGER PRIMARY KEY AUTOINCREMENT,
            ${NotificationColumns.uid} TEXT NOT NULL,
            ${NotificationColumns.title} TEXT NOT NULL,
            ${NotificationColumns.message} TEXT NOT NULL,
            ${NotificationColumns.createdAt} TEXT NOT NULL,
            ${NotificationColumns.read} INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE ${UserDataTables.shoppingListItems} (
            ${ShoppingListItemColumns.uid} TEXT NOT NULL,
            ${ShoppingListItemColumns.itemCode} TEXT NOT NULL,
            ${ShoppingListItemColumns.quantity} INTEGER NOT NULL,
            ${ShoppingListItemColumns.premiseCode} TEXT,
            PRIMARY KEY (${ShoppingListItemColumns.uid}, ${ShoppingListItemColumns.itemCode})
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Cart items gained a "which store did you pick" column so Add
          // to Cart can remember a specific store instead of always
          // implying the cheapest one. Existing rows just read back with
          // premise_code = NULL, which callers treat as "fall back to
          // cheapest" — no data loss.
          await db.execute('''
            ALTER TABLE ${UserDataTables.shoppingListItems}
            ADD COLUMN ${ShoppingListItemColumns.premiseCode} TEXT
          ''');
        }
      },
    );
  }
}
