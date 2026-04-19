import 'package:cloud_firestore/cloud_firestore.dart';

/// Live counts for [AdminMarketplacePulsePage]. All reads are scoped and best‑effort
/// (limits) so large datasets do not freeze the UI.
class AdminMetricsSnapshot {
  const AdminMetricsSnapshot({
    required this.productCount,
    required this.publishedProductCount,
    required this.draftProductCount,
    required this.orderCount,
    required this.pendingSubmissionCount,
    required this.ordersByStatus,
    required this.userProfilesSnapshotCount,
    required this.partnerVendorStoreCount,
    required this.customerRoleCount,
    this.loadError,
  });

  final int productCount;
  final int publishedProductCount;
  final int draftProductCount;
  final int orderCount;
  final int pendingSubmissionCount;
  final Map<String, int> ordersByStatus;
  /// Doc count from `users` query (capped — not necessarily total registered).
  final int userProfilesSnapshotCount;
  /// `users` where role is partner / vendor / store (same batch).
  final int partnerVendorStoreCount;
  /// Remaining profiles in batch (customer / unset role).
  final int customerRoleCount;
  final String? loadError;

  static AdminMetricsSnapshot error(Object e) => AdminMetricsSnapshot(
        productCount: 0,
        publishedProductCount: 0,
        draftProductCount: 0,
        orderCount: 0,
        pendingSubmissionCount: 0,
        ordersByStatus: const {},
        userProfilesSnapshotCount: 0,
        partnerVendorStoreCount: 0,
        customerRoleCount: 0,
        loadError: '$e',
      );
}

class AdminMetricsFirestore {
  AdminMetricsFirestore([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const _cap = 400;

  Future<AdminMetricsSnapshot> fetch() async {
    try {
      final products = await _db.collection('products').limit(_cap).get();
      var published = 0;
      var draft = 0;
      for (final d in products.docs) {
        final p = d.data()['published'] as bool?;
        if (p == false) {
          draft++;
        } else {
          published++;
        }
      }

      final orders = await _db.collection('orders').limit(_cap).get();
      final byStatus = <String, int>{};
      for (final d in orders.docs) {
        final s = d.data()['status'] as String? ?? 'unknown';
        byStatus[s] = (byStatus[s] ?? 0) + 1;
      }

      // Count pending client-side so we do not require a Firestore composite index
      // on `approvalStatus` (and still treat missing / blank status as pending).
      final submissions =
          await _db.collection('listing_submissions').limit(_cap).get();
      var pendingSubs = 0;
      for (final d in submissions.docs) {
        final raw = d.data()['approvalStatus'];
        if (raw == null) {
          pendingSubs++;
          continue;
        }
        if (raw is! String) {
          pendingSubs++;
          continue;
        }
        final s = raw.trim().toLowerCase();
        if (s.isEmpty || s == 'pending') pendingSubs++;
      }

      final usersSnap = await _db.collection('users').limit(_cap).get();
      var partners = 0;
      var customers = 0;
      for (final d in usersSnap.docs) {
        final r = (d.data()['role'] as String?)?.trim().toLowerCase();
        if (r == 'partner' || r == 'vendor' || r == 'store') {
          partners++;
        } else {
          customers++;
        }
      }

      return AdminMetricsSnapshot(
        productCount: products.docs.length,
        publishedProductCount: published,
        draftProductCount: draft,
        orderCount: orders.docs.length,
        pendingSubmissionCount: pendingSubs,
        ordersByStatus: byStatus,
        userProfilesSnapshotCount: usersSnap.docs.length,
        partnerVendorStoreCount: partners,
        customerRoleCount: customers,
      );
    } on Object catch (e) {
      return AdminMetricsSnapshot.error(e);
    }
  }
}
