import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/notifications/in_app_notifications.dart';

/// Admin review of vendor mushroom listings (`listing_submissions`).
/// Approved items are written to global `products` + `stores/{storeId}/inventory`.
class AdminListingSubmissionsService {
  AdminListingSubmissionsService([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<QuerySnapshot<Map<String, dynamic>>> watchPending() {
    return _db
        .collection('listing_submissions')
        .where('approvalStatus', isEqualTo: 'pending')
        .snapshots();
  }

  /// Admin-wide feed (pending + reviewed). UI can partition locally.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchAll() {
    return _db.collection('listing_submissions').snapshots();
  }

  Future<void> reject({
    required String submissionId,
    required String reason,
  }) async {
    final subRef =
        _db.collection('listing_submissions').doc(submissionId);
    final snap = await subRef.get();
    if (!snap.exists) {
      throw StateError('Submission not found.');
    }
    final m = snap.data()!;
    final vendorUid = m['submittedByUid'] as String?;

    final batch = _db.batch();
    batch.update(subRef, {
      'approvalStatus': 'rejected',
      'rejectionReason': reason,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
    if (vendorUid != null && vendorUid.isNotEmpty) {
      final nRef = _db.collection(InAppNotifications.collection).doc();
      batch.set(nRef, {
        'recipientUid': vendorUid,
        'title': 'Listing rejected',
        'body': reason.trim().isNotEmpty
            ? reason.trim()
            : 'Your submission was not approved.',
        'kind': 'listing_rejected',
        'relatedId': submissionId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  /// Publishes catalog entry + store inventory row; marks submission approved.
  Future<void> approve(String submissionId) async {
    final subRef =
        _db.collection('listing_submissions').doc(submissionId);
    final snap = await subRef.get();
    if (!snap.exists) {
      throw StateError('Submission not found.');
    }
    final m = snap.data()!;
    if ((m['approvalStatus'] as String?) != 'pending') {
      throw StateError('Submission is not pending.');
    }
    final storeId = m['storeId'] as String?;
    final vendorUid = m['submittedByUid'] as String?;
    final title = m['title'] as String? ?? 'Product';
    final description = m['description'] as String? ?? '';
    final priceMinor = (m['priceMinor'] as num?)?.toInt() ?? 0;
    final stock = (m['stock'] as num?)?.toInt() ?? 0;
    final varietyLabel =
        m['varietyLabel'] as String? ?? m['title'] as String? ?? 'Standard';

    if (storeId == null || storeId.isEmpty) {
      throw StateError('Submission missing storeId.');
    }

    const variantId = '101';
    final batch = _db.batch();

    batch.set(
      _db.collection('products').doc(submissionId),
      {
        'id': submissionId,
        'name': title,
        'description': description,
        'image_url': m['imageUrl'] as String? ?? '',
        'variants': [
          {
            'id': variantId,
            'label': varietyLabel,
            'priceMinor': priceMinor,
            'stock': stock,
            'lowStockThreshold': 8,
          },
        ],
        'published': true,
        'fromSubmission': true,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    final invKey = '${submissionId}_$variantId';
    batch.set(
      _db.collection('stores').doc(storeId).collection('inventory').doc(invKey),
      {
        'productId': submissionId,
        'variantId': variantId,
        'productName': title,
        'label': varietyLabel,
        'stock': stock,
        'priceMinor': priceMinor,
        'storeId': storeId,
        'submissionId': submissionId,
        'approvalStatus': 'approved',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.update(subRef, {
      'approvalStatus': 'approved',
      'reviewedAt': FieldValue.serverTimestamp(),
      'publishedProductId': submissionId,
    });

    if (vendorUid != null && vendorUid.isNotEmpty) {
      final nRef = _db.collection(InAppNotifications.collection).doc();
      batch.set(nRef, {
        'recipientUid': vendorUid,
        'title': 'Listing approved',
        'body': '"$title" is now live in the catalog.',
        'kind': 'listing_approved',
        'relatedId': submissionId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}
