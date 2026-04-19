import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin writes to `coupons/{code}` — same shape as [firestore_test_seed] / cart rules.
class AdminCouponsFirestore {
  AdminCouponsFirestore([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<void> upsertCoupon({
    required String code,
    required int percentOff,
    int? maxRedemptions,
    bool active = true,
    List<int>? eligiblePackGrams,
    int? minPackGramsAnyLine,
  }) async {
    final id = code.trim().toUpperCase();
    if (id.isEmpty) {
      throw ArgumentError('Coupon code is required.');
    }
    await _db.collection('coupons').doc(id).set(
      {
        'code': id,
        'percentOff': percentOff,
        'active': active,
        if (maxRedemptions != null && maxRedemptions > 0)
          'maxRedemptions': maxRedemptions,
        if (eligiblePackGrams != null && eligiblePackGrams.isNotEmpty)
          'eligiblePackGrams': eligiblePackGrams,
        if (minPackGramsAnyLine != null && minPackGramsAnyLine > 0)
          'minPackGramsAnyLine': minPackGramsAnyLine,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> deleteCoupon(String code) async {
    final id = code.trim().toUpperCase();
    await _db.collection('coupons').doc(id).delete();
  }
}
