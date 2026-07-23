/// SQLite table and column names for the PriceCatcher data layer.
///
/// Kept in one place so tools/db_builder/build_pricecatcher_db.py and the
/// Flutter data layer never drift apart on naming.
class DatabaseTables {
  DatabaseTables._();

  static const String products = 'products';
  static const String supermarkets = 'supermarkets';

  /// Full price history, one row per (item, premise, date).
  static const String prices = 'prices';

  /// Current price per (item, premise) pair — what price-comparison
  /// screens should query, so they don't scan full history just to answer
  /// "what does this cost right now at each store".
  static const String latestPrices = 'latest_prices';
}

class ProductColumns {
  ProductColumns._();

  static const String itemCode = 'item_code';
  static const String name = 'name';
  static const String nameLower = 'name_lower';
  static const String unit = 'unit';
  static const String itemGroup = 'item_group';
  static const String itemCategory = 'item_category';
}

class SupermarketColumns {
  SupermarketColumns._();

  static const String premiseCode = 'premise_code';
  static const String name = 'name';
  static const String address = 'address';
  static const String premiseType = 'premise_type';
  static const String district = 'district';
  static const String state = 'state';
}

class PriceColumns {
  PriceColumns._();

  static const String itemCode = 'item_code';
  static const String premiseCode = 'premise_code';
  static const String date = 'date';
  static const String price = 'price';
}
