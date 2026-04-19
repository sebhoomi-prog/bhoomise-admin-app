import 'package:cloud_firestore/cloud_firestore.dart';

/// Shared Firestore gateway for coupon documents (`coupons/{code}`).
class SharedCouponFirestoreRepository {
  SharedCouponFirestoreRepository([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('coupons');

  Future<QuerySnapshot<Map<String, dynamic>>> fetchCoupons({int limit = 80}) =>
      _col.limit(limit).get();

  Future<DocumentSnapshot<Map<String, dynamic>>> fetchCoupon(String code) =>
      _col.doc(code.trim().toUpperCase()).get();
}
