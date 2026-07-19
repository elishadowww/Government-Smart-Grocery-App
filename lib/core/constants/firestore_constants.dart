/// Firestore collection paths and field names for the PriceCatcher data layer.
///
/// Kept in one place so the import script (scripts/import_pricecatcher.py)
/// and the Flutter data layer never drift apart on naming.
class FirestoreCollections {
  FirestoreCollections._();

  /// Product master data, keyed by PriceCatcher `item_code`.
  static const String products = 'products';

  /// Supermarket master data, keyed by PriceCatcher `premise_code`.
  static const String supermarkets = 'supermarkets';

  /// Full price history, one doc per (item, premise, date).
  /// Doc id: `{itemCode}_{premiseCode}_{date}`.
  static const String prices = 'prices';

  /// Materialized "current price" view, one doc per (item, premise).
  /// Doc id: `{itemCode}_{premiseCode}`. This is what price-comparison
  /// screens should read from — it avoids scanning full price history
  /// just to answer "what does this cost right now at each store".
  static const String latestPrices = 'latest_prices';
}

class ProductFields {
  ProductFields._();

  static const String itemCode = 'itemCode';
  static const String name = 'name';
  static const String nameLower = 'nameLower';
  static const String unit = 'unit';
  static const String itemGroup = 'itemGroup';
  static const String itemCategory = 'itemCategory';
}

class SupermarketFields {
  SupermarketFields._();

  static const String premiseCode = 'premiseCode';
  static const String name = 'name';
  static const String address = 'address';
  static const String premiseType = 'premiseType';
  static const String district = 'district';
  static const String state = 'state';
}

class PriceFields {
  PriceFields._();

  static const String itemCode = 'itemCode';
  static const String premiseCode = 'premiseCode';
  static const String date = 'date';
  static const String price = 'price';
  static const String updatedAt = 'updatedAt';
}
