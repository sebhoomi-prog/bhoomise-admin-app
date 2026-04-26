class AppConstants {
  AppConstants._();

  /// Production API base URL for deployed hostinger backend.
  ///
  /// This deployment is served under `/api` directory, while endpoints include
  /// `/api/...` path constants, resulting in final URLs like `/api/api/stores`.
  static const defaultApiBaseUrl = 'https://bhoomise.tech/api';

  static const apiPrefix = '/api';

  static const authSendOtp = '$apiPrefix/auth/send-otp';
  static const authVerifyOtp = '$apiPrefix/auth/verify-otp';
  static const me = '$apiPrefix/me';
  static const products = '$apiPrefix/products';
  static const coupons = '$apiPrefix/coupons';
  static const stores = '$apiPrefix/stores';
  static const orders = '$apiPrefix/orders';
  static const listingSubmissions = '$apiPrefix/listing-submissions';
  static const appDocs = '$apiPrefix/app';
  static const adminPhones = '$apiPrefix/admin-phones';
  static const users = '$apiPrefix/users';
  static const fast2SmsWebhook = '$apiPrefix/webhooks/fast2sms/delivery-report';

  static const headerAccept = 'Accept';
  static const headerAuthorization = 'Authorization';
  static const bearerPrefix = 'Bearer';
  static const valueApplicationJson = 'application/json';

  static const localeEnglish = 'en';
  static const localeHindi = 'hi';
  static const themeLight = 'light';
  static const themeDark = 'dark';
}
