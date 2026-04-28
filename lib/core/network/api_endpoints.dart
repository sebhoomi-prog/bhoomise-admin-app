import '../constants/app_constants.dart';

/// REST path segments when using Dio + [ApiClient] (`BackendConfig.hasRestApi`).
class ApiEndpoints {
  ApiEndpoints._();

  static const sendOtp = AppConstants.authSendOtp;
  static const verifyOtp = AppConstants.authVerifyOtp;
  static const me = AppConstants.me;
  static const products = AppConstants.products;
  static const catalogProductImages = AppConstants.catalogProductImages;
  static const orders = AppConstants.orders;
  static const coupons = AppConstants.coupons;
  static const stores = AppConstants.stores;
  static const listingSubmissions = AppConstants.listingSubmissions;
  static const appDocs = AppConstants.appDocs;
  static const users = AppConstants.users;
  static const adminPhones = AppConstants.adminPhones;
  static String storeInventory(String storeId) =>
      '${AppConstants.stores}/$storeId/inventory';
}
