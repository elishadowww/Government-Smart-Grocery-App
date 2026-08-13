/// SQLite table and column names for the on-device user data store
/// (assets/database is the read-only PriceCatcher catalog; this is a
/// separate, writable database for per-user app state).
///
/// Every table is keyed by Firebase Auth uid (including anonymous/guest
/// uids), so switching accounts on one device never leaks data between
/// users.
class UserDataTables {
  UserDataTables._();

  static const String savedProducts = 'saved_products';
  static const String recentSearches = 'recent_searches';
  static const String recentProducts = 'recent_products';
  static const String notifications = 'notifications';
  static const String shoppingListItems = 'shopping_list_items';
}

class SavedProductColumns {
  SavedProductColumns._();

  static const String uid = 'uid';
  static const String itemCode = 'item_code';
  static const String savedAt = 'saved_at';

  /// Cheapest price observed at the moment the product was saved (or last
  /// notified), so we can detect a price change and raise an alert.
  static const String trackedPrice = 'tracked_price';
}

class RecentSearchColumns {
  RecentSearchColumns._();

  static const String uid = 'uid';
  static const String term = 'term';
  static const String searchedAt = 'searched_at';
}

class RecentProductColumns {
  RecentProductColumns._();

  static const String uid = 'uid';
  static const String itemCode = 'item_code';
  static const String viewedAt = 'viewed_at';
}

class NotificationColumns {
  NotificationColumns._();

  static const String id = 'id';
  static const String uid = 'uid';
  static const String title = 'title';
  static const String message = 'message';
  static const String createdAt = 'created_at';
  static const String read = 'read';
}

class ShoppingListItemColumns {
  ShoppingListItemColumns._();

  static const String uid = 'uid';
  static const String itemCode = 'item_code';
  static const String quantity = 'quantity';

  /// The supermarket the user chose to buy this item from — nullable so
  /// rows written before this column existed (pre-migration) still read
  /// back fine; callers fall back to the cheapest store for those.
  static const String premiseCode = 'premise_code';
}
