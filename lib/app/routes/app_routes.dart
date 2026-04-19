class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const login = '/login';
  static const otp = '/otp';
  static const signupProfile = '/signup-profile';
  static const profileEdit = '/profile-edit';
  static const home = '/home';
  /// Business / Admin main shell (inventory, supply hub — Figma partner flows).
  static const partnerShell = '/partner-shell';
  static const productDetail = '/product';
  static const orderTrack = '/order';
  /// Browse / apply promotions (cart “See all coupons”).
  static const availableCoupons = '/coupons';
  static const addresses = '/addresses';
  static const addressForm = '/address-form';

  /// Store / retailer (B2B + inventory)
  static const storeInventory = '/store/inventory';
  static const storeQuickSale = '/store/quick-sale';
  /// Vendor listing creation — Figma **Add New Cultivation**.
  static const vendorAddCultivation = '/vendor/add-cultivation';
  /// Vendor inventory list — Figma **Curated Collections** (same UI as shell Products tab).
  static const vendorCuratedCollections = '/vendor/curated-collections';
  /// Incoming harvest / order queue — Figma **Orders** tab (shell); legacy route remains [adminSupplyOrders].
  static const vendorHarvestRequests = '/vendor/harvest-requests';

  /// Admin / supplier hub
  static const adminSupply = '/admin/supply';
  static const adminSupplyOrders = '/admin/supply-orders';
  /// Edit customer home category tiles (`app/customer_home` in Firestore).
  static const adminCustomerHome = '/admin/customer-home';
  /// Browse master product taxonomy (admin tools).
  static const adminMasterProducts = '/admin/master-products';
  /// Firestore `users` directory (admin).
  static const adminUsersDirectory = '/admin/users';
  /// Orders + metrics snapshot (admin).
  static const adminAuditActivity = '/admin/audit';
  /// Access control notes + signed-in operator (admin).
  static const adminSecurityCenter = '/admin/security';
  /// Firebase project + live counts (admin).
  static const adminPlatformConsole = '/admin/platform';
}
