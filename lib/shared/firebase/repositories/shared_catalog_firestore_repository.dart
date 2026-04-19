import 'package:cloud_firestore/cloud_firestore.dart';

/// Shared Firestore gateway for customer-facing catalog (`products`).
class SharedCatalogFirestoreRepository {
  SharedCatalogFirestoreRepository([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<QuerySnapshot<Map<String, dynamic>>> fetchProducts() =>
      _db.collection('products').get();
}
