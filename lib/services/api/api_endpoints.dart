abstract final class ApiEndpoints {
  ApiEndpoints._();

  static const up = '/up';

  static const sendOtp = '/api/auth/send-otp';
  static const verifyOtp = '/api/auth/verify-otp';
  static const me = '/api/me';

  static const products = '/api/products';
  static String product(String productId) => '/api/products/$productId';
  static const catalogProductImages = '/api/catalog/product-images';

  static const coupons = '/api/coupons';
  static String coupon(String couponCode) => '/api/coupons/$couponCode';

  static const stores = '/api/stores';
  static String store(String storeId) => '/api/stores/$storeId';
  static String storeInventory(String storeId) => '/api/stores/$storeId/inventory';
  static String upsertStoreInventory(String storeId, String inventoryKey) =>
      '/api/stores/$storeId/inventory/$inventoryKey';

  static const listingSubmissions = '/api/listing-submissions';
  static String listingSubmission(String id) => '/api/listing-submissions/$id';

  static const orders = '/api/orders';
  static String order(String id) => '/api/orders/$id';

  static const users = '/api/users';

  static const adminPhones = '/api/admin-phones';
  static String adminPhone(String phone) => '/api/admin-phones/$phone';

  static const appDocs = '/api/app';
  static String appDoc(String appDocId) => '/api/app/$appDocId';
}

