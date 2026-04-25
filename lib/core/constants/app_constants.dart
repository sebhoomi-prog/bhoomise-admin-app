class AppConstants {
  AppConstants._();

  /// Production API base URL.
  ///
  /// Laravel routes are nested under `/api/...` on this host.
  /// Our endpoint constants include an `/api` prefix, so this default intentionally
  /// ends with `/api` as well to match the deployed routing (and Postman collection).
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
