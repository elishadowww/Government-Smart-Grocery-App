import '../core/constants/firestore_constants.dart';
import '../core/services/firestore_service.dart';
import '../models/product.dart';

/// Data access for the `products` Firestore collection.
class ProductRepository {
  ProductRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  final FirestoreService _firestoreService;

  static const _collectionPath = FirestoreCollections.products;

  Future<Product?> getById(String itemCode) async {
    final doc = await _firestoreService
        .collection(_collectionPath)
        .doc(itemCode)
        .get();
    if (!doc.exists) return null;
    return Product.fromFirestore(doc);
  }

  /// Prefix search over the lowercased product name.
  ///
  /// Relies on the `nameLower` field written by the import script, since
  /// Firestore has no native full-text search.
  Future<List<Product>> searchByName(String query, {int limit = 20}) async {
    final lower = query.trim().toLowerCase();
    if (lower.isEmpty) return const [];

    final snapshot = await _firestoreService
        .collection(_collectionPath)
        .orderBy(ProductFields.nameLower)
        .startAt([lower])
        .endAt(['$lower'])
        .limit(limit)
        .get();

    return snapshot.docs.map(Product.fromFirestore).toList();
  }

  Future<List<Product>> getByCategory(String itemCategory, {int limit = 50}) async {
    final snapshot = await _firestoreService
        .collection(_collectionPath)
        .where(ProductFields.itemCategory, isEqualTo: itemCategory)
        .orderBy(ProductFields.nameLower)
        .limit(limit)
        .get();

    return snapshot.docs.map(Product.fromFirestore).toList();
  }

  Stream<List<Product>> watchByCategory(String itemCategory) {
    return _firestoreService
        .collection(_collectionPath)
        .where(ProductFields.itemCategory, isEqualTo: itemCategory)
        .orderBy(ProductFields.nameLower)
        .snapshots()
        .map((snap) => snap.docs.map(Product.fromFirestore).toList());
  }

  Future<List<Product>> getAll({int limit = 50}) async {
    final snapshot =
        await _firestoreService.collection(_collectionPath).limit(limit).get();
    return snapshot.docs.map(Product.fromFirestore).toList();
  }
}
