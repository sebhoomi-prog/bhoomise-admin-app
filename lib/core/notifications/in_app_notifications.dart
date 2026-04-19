import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore-backed inbox for admins and users. Real-time in app; pair with FCM + Cloud Functions for push.
///
/// [adminBroadcastRecipient] targets every signed-in admin reading the admin feed.
class InAppNotifications {
  InAppNotifications([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const collection = 'notifications';
  static const adminBroadcastRecipient = 'ADMIN_BROADCAST';

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(collection);

  /// Vendor submitted a listing — all admins see this in their profile feed.
  Future<void> notifyAdminsNewListing({
    required String submissionId,
    required String title,
    required String storeId,
  }) async {
    await _col.add({
      'recipientUid': adminBroadcastRecipient,
      'title': 'New vendor listing',
      'body': '"$title" · store $storeId — review in SPORE.',
      'kind': 'vendor_listing_submitted',
      'relatedId': submissionId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Listing approved or rejected — notify submitting vendor by Firebase Auth uid.
  Future<void> notifyVendorListingDecision({
    required String vendorUid,
    required String submissionId,
    required bool approved,
    String? rejectionReason,
  }) async {
    await _col.add({
      'recipientUid': vendorUid,
      'title': approved ? 'Listing approved' : 'Listing rejected',
      'body': approved
          ? 'Your product was published to the catalog.'
          : (rejectionReason != null && rejectionReason.trim().isNotEmpty
              ? rejectionReason.trim()
              : 'Your submission was not approved. Open Partner → SPORE for details.'),
      'kind': approved ? 'listing_approved' : 'listing_rejected',
      'relatedId': submissionId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Admin feed (broadcast).
  Stream<QuerySnapshot<Map<String, dynamic>>> watchAdminFeed({int limit = 40}) {
    return _col
        .where('recipientUid', isEqualTo: adminBroadcastRecipient)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Messages to the signed-in user (vendor/customer).
  Stream<QuerySnapshot<Map<String, dynamic>>> watchForUser(
    String uid, {
    int limit = 30,
  }) {
    return _col
        .where('recipientUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }
}
