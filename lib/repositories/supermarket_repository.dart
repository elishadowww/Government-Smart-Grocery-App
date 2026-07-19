import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_constants.dart';
import '../core/services/firestore_service.dart';
import '../models/supermarket.dart';

/// Data access for the `supermarkets` Firestore collection.
class SupermarketRepository {
  SupermarketRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  final FirestoreService _firestoreService;

  static const _collectionPath = FirestoreCollections.supermarkets;

  Future<Supermarket?> getById(String premiseCode) async {
    final doc = await _firestoreService
        .collection(_collectionPath)
        .doc(premiseCode)
        .get();
    if (!doc.exists) return null;
    return Supermarket.fromFirestore(doc);
  }

  Future<List<Supermarket>> getByState(String state, {int limit = 100}) async {
    final snapshot = await _firestoreService
        .collection(_collectionPath)
        .where(SupermarketFields.state, isEqualTo: state)
        .limit(limit)
        .get();
    return snapshot.docs.map(Supermarket.fromFirestore).toList();
  }

  Future<List<Supermarket>> getByDistrict(String district, {int limit = 100}) async {
    final snapshot = await _firestoreService
        .collection(_collectionPath)
        .where(SupermarketFields.district, isEqualTo: district)
        .limit(limit)
        .get();
    return snapshot.docs.map(Supermarket.fromFirestore).toList();
  }

  /// Fetch multiple supermarkets by id in one round trip.
  ///
  /// Firestore's `whereIn` caps out at 30 values, so callers with larger
  /// id lists should chunk them.
  Future<List<Supermarket>> getByIds(List<String> premiseCodes) async {
    if (premiseCodes.isEmpty) return const [];
    final snapshot = await _firestoreService
        .collection(_collectionPath)
        .where(FieldPath.documentId, whereIn: premiseCodes)
        .get();
    return snapshot.docs.map(Supermarket.fromFirestore).toList();
  }

  Future<List<Supermarket>> getAll({int limit = 100}) async {
    final snapshot =
        await _firestoreService.collection(_collectionPath).limit(limit).get();
    return snapshot.docs.map(Supermarket.fromFirestore).toList();
  }
}
