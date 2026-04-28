import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../models/api/admin_api_models.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';

/// Admin API service for all admin-related operations.
///
/// All endpoints require Bearer token authentication.
/// Token is automatically attached via [AuthBearerInterceptor].
class AdminApiService {
  AdminApiService(this._api);

  final ApiClient _api;

  // ─────────────────────────────────────────────────────────────────
  // User Profile
  // ─────────────────────────────────────────────────────────────────

  Future<User> getMe() async {
    final response = await _api.get(ApiEndpoints.me);
    final data = _payload(response.data);
    if (data is Map) {
      final m = _asStringKeyMap(data);
      final user = m['user'];
      if (user is Map) {
        return User.fromJson(_asStringKeyMap(user));
      }
      return User.fromJson(m);
    }
    throw StateError('Invalid /me response');
  }

  // ─────────────────────────────────────────────────────────────────
  // Products
  // ─────────────────────────────────────────────────────────────────

  Future<List<Product>> listProducts() async {
    final response = await _api.get(ApiEndpoints.products);
    final raw = _listFromPayload(response.data, 'products');
    return raw
        .map((p) => Product.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<Product> upsertProduct(String productId, Product product) async {
    final response = await _api.put(
      '${ApiEndpoints.products}/$productId',
      body: product.toJson(),
    );
    final obj = _objectFromPayload(response.data, 'product');
    return Product.fromJson(obj);
  }

  /// Uploads a raster for master catalog; returns public HTTPS URL stored by the API.
  Future<String> uploadCatalogProductImage({
    required Uint8List bytes,
    required String filename,
  }) async {
    final safeName = filename.trim().isEmpty
        ? 'product_${DateTime.now().millisecondsSinceEpoch}.jpg'
        : filename.trim();
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: safeName),
    });
    final response = await _api.postMultipart(
      ApiEndpoints.catalogProductImages,
      data: form,
    );
    final data = _payload(response.data);
    if (data is Map) {
      final m = _asStringKeyMap(data);
      final url = m['url']?.toString();
      if (url != null && url.isNotEmpty) {
        return url;
      }
    }
    throw StateError('Invalid catalog image upload response');
  }

  Future<void> deleteProduct(String productId) async {
    await _api.delete('${ApiEndpoints.products}/$productId');
  }

  // ─────────────────────────────────────────────────────────────────
  // Coupons
  // ─────────────────────────────────────────────────────────────────

  Future<List<Coupon>> listCoupons() async {
    final response = await _api.get(ApiEndpoints.coupons);
    final raw = _listFromPayload(response.data, 'coupons');
    return raw
        .map((c) => Coupon.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<Coupon> upsertCoupon(String couponCode, Coupon coupon) async {
    final response = await _api.put(
      '${ApiEndpoints.coupons}/$couponCode',
      body: coupon.toJson(),
    );
    final obj = _objectFromPayload(response.data, 'coupon');
    return Coupon.fromJson(obj);
  }

  Future<void> deleteCoupon(String couponCode) async {
    await _api.delete('${ApiEndpoints.coupons}/$couponCode');
  }

  // ─────────────────────────────────────────────────────────────────
  // Stores
  // ─────────────────────────────────────────────────────────────────

  Future<List<Store>> listStores() async {
    final response = await _api.get(ApiEndpoints.stores);
    final raw = _listFromPayload(response.data, 'stores');
    return raw.map((s) => Store.fromJson(s as Map<String, dynamic>)).toList();
  }

  Future<Store> upsertStore(String storeId, Store store) async {
    final response = await _api.put(
      '${ApiEndpoints.stores}/$storeId',
      body: store.toJson(),
    );
    final obj = _objectFromPayload(response.data, 'store');
    return Store.fromJson(obj);
  }

  // ─────────────────────────────────────────────────────────────────
  // Store Inventory
  // ─────────────────────────────────────────────────────────────────

  Future<List<StoreInventoryItem>> getStoreInventory(String storeId) async {
    final response = await _api.get(ApiEndpoints.storeInventory(storeId));
    final raw = _listFromPayload(response.data, 'inventory');
    return raw
        .map((i) => StoreInventoryItem.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  Future<StoreInventoryItem> upsertStoreInventory(
    String storeId,
    StoreInventoryItem item,
  ) async {
    final response = await _api.put(
      '${ApiEndpoints.storeInventory(storeId)}/${item.inventoryKey}',
      body: item.toJson(),
    );
    final obj = _objectFromPayload(response.data, 'inventory');
    return StoreInventoryItem.fromJson(obj);
  }

  // ─────────────────────────────────────────────────────────────────
  // Orders
  // ─────────────────────────────────────────────────────────────────

  Future<List<Order>> listOrders() async {
    final response = await _api.get(ApiEndpoints.orders);
    final raw = _listFromPayload(response.data, 'orders');
    return raw.map((o) => Order.fromJson(o as Map<String, dynamic>)).toList();
  }

  Future<Order> upsertOrder(String orderId, Order order) async {
    final response = await _api.put(
      '${ApiEndpoints.orders}/$orderId',
      body: order.toJson(),
    );
    final obj = _objectFromPayload(response.data, 'order');
    return Order.fromJson(obj);
  }

  // ─────────────────────────────────────────────────────────────────
  // Listing Submissions
  // ─────────────────────────────────────────────────────────────────

  Future<List<ListingSubmission>> listSubmissions({String? storeId}) async {
    final response = await _api.get(
      ApiEndpoints.listingSubmissions,
      query: storeId != null ? {'storeId': storeId} : null,
    );
    final raw = _listFromPayload(
      response.data,
      'listing_submissions',
      ['listingSubmissions', 'submissions'],
    );
    return raw
        .map((s) => ListingSubmission.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<ListingSubmission> updateSubmission(
    String submissionId, {
    String? approvalStatus,
    int? stock,
  }) async {
    final body = <String, dynamic>{};
    if (approvalStatus != null) body['approvalStatus'] = approvalStatus;
    if (stock != null) body['stock'] = stock;

    final response = await _api.put(
      '${ApiEndpoints.listingSubmissions}/$submissionId',
      body: body,
    );
    final obj = _objectFromPayload(response.data, 'listing_submission');
    return ListingSubmission.fromJson(obj);
  }

  // ─────────────────────────────────────────────────────────────────
  // Users (Admin only)
  // ─────────────────────────────────────────────────────────────────

  Future<List<User>> listUsers() async {
    final response = await _api.get(ApiEndpoints.users);
    final raw = _listFromPayload(response.data, 'users');
    return raw.map((u) => User.fromJson(u as Map<String, dynamic>)).toList();
  }

  // ─────────────────────────────────────────────────────────────────
  // Admin Phones
  // ─────────────────────────────────────────────────────────────────

  Future<List<AdminPhone>> listAdminPhones() async {
    final response = await _api.get(ApiEndpoints.adminPhones);
    final raw = _listFromPayload(response.data, 'admin_phones');
    return raw
        .map((p) => AdminPhone.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<void> upsertAdminPhone(String phone) async {
    await _api.put('${ApiEndpoints.adminPhones}/$phone');
  }

  // ─────────────────────────────────────────────────────────────────
  // App Docs
  // ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAppDoc(String docId) async {
    final response = await _api.get('${ApiEndpoints.appDocs}/$docId');
    final doc = _objectFromPayload(response.data, 'doc');
    if (doc.isNotEmpty) return doc;
    final fallback = _payload(response.data);
    if (fallback is Map) return _asStringKeyMap(fallback);
    return {};
  }

  Future<void> upsertAppDoc(String docId, Map<String, dynamic> doc) async {
    await _api.put('${ApiEndpoints.appDocs}/$docId', body: doc);
  }
}

dynamic _payload(dynamic body) {
  if (body is Map && body['data'] != null) return body['data'];
  return null;
}

Map<String, dynamic> _asStringKeyMap(Map<dynamic, dynamic> m) =>
    Map<String, dynamic>.from(m);

/// Backend wraps collections as `{ data: { key: [ ... ] } }`.
List<dynamic> _listFromPayload(
  dynamic body,
  String key, [
  List<String> alternateKeys = const [],
]) {
  final data = _payload(body);
  if (data is List) return data;
  if (data is Map) {
    final m = _asStringKeyMap(data);
    for (final k in [key, ...alternateKeys]) {
      final v = m[k];
      if (v is List) return v;
    }
  }
  return [];
}

Map<String, dynamic> _objectFromPayload(dynamic body, String key) {
  final data = _payload(body);
  if (data is Map) {
    final m = _asStringKeyMap(data);
    final v = m[key];
    if (v is Map) return _asStringKeyMap(v);
    return m;
  }
  return {};
}
