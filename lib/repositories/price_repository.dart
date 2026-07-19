import '../core/constants/firestore_constants.dart';
import '../core/services/firestore_service.dart';
import '../models/price.dart';

/// Data access for price data: the `latest_prices` comparison view and the
/// `prices` full history collection.
class PriceRepository {
  PriceRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  final FirestoreService _firestoreService;

  /// Current price for [itemCode] at every supermarket that stocks it,
  /// cheapest first. This is what Module 1's price-comparison screen
  /// should call.
  Future<List<Price>> getLatestPricesForItem(
    String itemCode, {
    int limit = 100,
  }) async {
    final snapshot = await _firestoreService
        .collection(FirestoreCollections.latestPrices)
        .where(PriceFields.itemCode, isEqualTo: itemCode)
        .orderBy(PriceFields.price)
        .limit(limit)
        .get();
    return snapshot.docs.map(Price.fromFirestore).toList();
  }

  /// Current price for [itemCode] at a single [premiseCode], if any.
  Future<Price?> getLatestPrice(String itemCode, String premiseCode) async {
    final doc = await _firestoreService
        .collection(FirestoreCollections.latestPrices)
        .doc('${itemCode}_$premiseCode')
        .get();
    if (!doc.exists) return null;
    return Price.fromFirestore(doc);
  }

  /// Historical prices for [itemCode], optionally scoped to one
  /// [premiseCode], ordered oldest to newest. Powers Module 4 (price
  /// trends).
  Future<List<Price>> getHistory({
    required String itemCode,
    String? premiseCode,
    DateTime? since,
    int limit = 200,
  }) async {
    var query = _firestoreService
        .collection(FirestoreCollections.prices)
        .where(PriceFields.itemCode, isEqualTo: itemCode);

    if (premiseCode != null) {
      query = query.where(PriceFields.premiseCode, isEqualTo: premiseCode);
    }

    query = query.orderBy(PriceFields.date);

    if (since != null) {
      final sinceStr = since.toIso8601String().split('T').first;
      // Cursor values must line up with the query's orderBy clauses — here
      // that's just `date`, since itemCode/premiseCode are equality filters.
      query = query.startAt([sinceStr]);
    }

    final snapshot = await query.limit(limit).get();
    return snapshot.docs.map(Price.fromFirestore).toList();
  }
}
