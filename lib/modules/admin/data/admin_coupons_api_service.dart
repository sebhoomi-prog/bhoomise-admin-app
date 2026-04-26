import '../../../services/admin/admin_api_service.dart';
import '../../../models/api/admin_api_models.dart';

/// Admin coupon operations via REST API.
class AdminCouponsApiService {
  AdminCouponsApiService(this._api);

  final AdminApiService _api;

  Future<List<Coupon>> listCoupons() async {
    return _api.listCoupons();
  }

  Future<Coupon> upsertCoupon({
    required String code,
    required int percentOff,
    int? maxRedemptions,
    bool active = true,
    List<int>? eligiblePackGrams,
    int? minPackGramsAnyLine,
    DateTime? expiresAt,
  }) async {
    final id = code.trim().toUpperCase();
    if (id.isEmpty) {
      throw ArgumentError('Coupon code is required.');
    }
    
    final coupon = Coupon(
      code: id,
      percentOff: percentOff,
      active: active,
      maxRedemptions: maxRedemptions,
      eligiblePackGrams: eligiblePackGrams,
      minPackGramsAnyLine: minPackGramsAnyLine,
      expiresAt: expiresAt,
    );
    
    return _api.upsertCoupon(id, coupon);
  }

  Future<void> deleteCoupon(String code) async {
    final id = code.trim().toUpperCase();
    await _api.deleteCoupon(id);
  }
}
