import 'package:cloud_firestore/cloud_firestore.dart';

/// Thin wrapper around [FirebaseFirestore] shared by every repository.
///
/// Repositories depend on this instead of `FirebaseFirestore.instance`
/// directly, so a fake/in-memory Firestore instance can be injected in
/// tests without touching repository code.
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  FirebaseFirestore get instance => _firestore;

  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _firestore.collection(path);
  }
}
