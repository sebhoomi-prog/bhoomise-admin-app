import '../../../services/admin/admin_api_service.dart';
import '../../../services/api/api_client.dart';

/// Admin metrics from REST API instead of Firestore.
class AdminMetricsSnapshot {
  const AdminMetricsSnapshot({
    required this.productsCount,
    required this.ordersCount,
    required this.usersCount,
    required this.storesCount,
    this.publishedProductCount = 0,
    this.draftProductCount = 0,
    this.pendingSubmissionCount = 0,
    this.partnerVendorStoreCount = 0,
    this.customerRoleCount = 0,
    this.ordersByStatus = const {},
    this.loadError,
  });

  final int productsCount;
  final int publishedProductCount;
  final int draftProductCount;
  final int ordersCount;
  final int usersCount;
  final int storesCount;
  final int pendingSubmissionCount;
  final int partnerVendorStoreCount;
  final int customerRoleCount;
  final Map<String, int> ordersByStatus;
  final String? loadError;

  int get productCount => productsCount;
  int get orderCount => ordersCount;
  int get userProfilesSnapshotCount => usersCount;

  static AdminMetricsSnapshot error(Object e) => AdminMetricsSnapshot(
        productsCount: 0,
        ordersCount: 0,
        usersCount: 0,
        storesCount: 0,
        loadError: '$e',
      );
}

class AdminMetricsApiService {
  AdminMetricsApiService(ApiClient client) : _api = AdminApiService(client);

  final AdminApiService _api;

  Future<AdminMetricsSnapshot> fetch() async {
    try {
      final products = await _api.listProducts();
      final orders = await _api.listOrders();
      final users = await _api.listUsers();
      final stores = await _api.listStores();
      final submissions = await _api.listSubmissions();

      var published = 0;
      var draft = 0;
      for (final p in products) {
        if (p.published) {
          published++;
        } else {
          draft++;
        }
      }

      final byStatus = <String, int>{};
      for (final o in orders) {
        final s = o.status.isNotEmpty ? o.status : 'unknown';
        byStatus[s] = (byStatus[s] ?? 0) + 1;
      }

      var pendingSubs = 0;
      for (final s in submissions) {
        final status = s.approvalStatus?.toLowerCase() ?? '';
        if (status.isEmpty || status == 'pending') pendingSubs++;
      }

      var partners = 0;
      var customers = 0;
      for (final u in users) {
        final r = u.role?.toLowerCase() ?? '';
        if (r == 'partner' || r == 'vendor' || r == 'store' || r == 'admin') {
          partners++;
        } else {
          customers++;
        }
      }

      return AdminMetricsSnapshot(
        productsCount: products.length,
        publishedProductCount: published,
        draftProductCount: draft,
        ordersCount: orders.length,
        usersCount: users.length,
        storesCount: stores.length,
        pendingSubmissionCount: pendingSubs,
        ordersByStatus: byStatus,
        partnerVendorStoreCount: partners,
        customerRoleCount: customers,
      );
    } catch (e) {
      return AdminMetricsSnapshot.error(e);
    }
  }
}
