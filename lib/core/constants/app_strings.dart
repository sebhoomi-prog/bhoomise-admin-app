/// User-facing copy centralized for consistency and future localization.
class AppStrings {
  AppStrings._();

  static const appName = 'Bhoomise';
  static const tagline = 'Smart agri-commerce & inventory';

  /// Bottom nav — matches Figma customer shell.
  static const navHome = 'Home';
  static const navSearch = 'Search';
  /// Order history / bag — Figma label **ORDERS**.
  static const navOrders = 'Orders';
  static const navBasket = 'Basket';
  static const navProfile = 'Profile';

  static const yourBasket = 'Your Basket';
  static const catalog = 'Browse products';
  static const cart = 'Cart';
  static const addToCart = 'Add to cart';
  /// Live cart confirmation (after add / +/- on home & search).
  static String cartFeedbackDeltaTitle(int delta, String productShort) {
    final d = delta > 0 ? '+$delta' : '$delta';
    return '$d · $productShort';
  }

  static String cartFeedbackLineAndBag(int lineQty, int bagTotal) =>
      '$lineQty of this item · $bagTotal in your bag';
  static String cartFeedbackRemoved(String productShort) =>
      'Removed from bag · $productShort';

  static String cartItemsStillInBag(int count) =>
      '$count item${count == 1 ? '' : 's'} still in your bag';

  static const emptyCart = 'Your cart is empty';
  static const cartLineItemsHint =
      'Each pack size is its own line — adjust quantities independently.';
  static const total = 'Total';
  static String curatedItemsSelected(int count) =>
      '$count curated item${count == 1 ? '' : 's'} selected';
  static String subtotalWithItemCount(int count) => 'Subtotal ($count items)';
  static const voucherCode = 'Voucher Code';
  static const voucherPlaceholder = 'Enter your code';
  static const apply = 'Apply';
  static const seeAllCoupons = 'See all coupons';
  static const availableCouponsHeroKicker = 'CURATED SAVINGS';
  static const availableCouponsTitle = 'Available coupons';
  static const availableCouponsSubtitle =
      'Harvest the best deals from our network of organic growers.';
  static const filterCouponsAll = 'All coupons';
  static const filterCouponsActive = 'Active';
  static const filterCouponsExpiring = 'Expiring soon';
  static const couponNoExpiry = 'No expiry listed';
  static const couponExpired = 'Expired';
  static String couponExpiresInHours(int h) => 'Expires in ${h}h';
  static String couponExpiresOn(String date) => 'Expires $date';
  static const couponReferralTitle = 'Looking for more?';
  static const couponReferralBody =
      'Refer a friend to unlock exclusive badges and premium discount codes.';
  static const couponReferralCta = 'Invite a grower';
  static const couponsEmptyFilter = 'No coupons match this filter.';
  static const couponsCatalogEmpty =
      'No offers are available yet. New codes appear here when your team adds them in admin.';
  static const couponCatalogLoadFailed =
      'Could not load promotions. Try again in a moment.';
  static const sustainableDelivery = 'Sustainable Delivery';
  static const ecoHandlingFee = 'Eco-Handling Fee';
  static const estimatedTaxes = 'Estimated Taxes';
  static const proceedToCheckout = 'Proceed to Checkout';
  static const secureEncryptedTransaction = 'SECURE ENCRYPTED TRANSACTION';
  static const invalidVoucher = 'That code is not valid.';
  static const voucherApplied = 'Voucher applied.';
  static const enterVoucherHint = 'Enter a voucher code.';
  static const voucherNeedsItems = 'Add items to your bag before applying a voucher.';
  static const voucherPackIneligible =
      'This voucher only applies to certain pack sizes in your bag.';
  static const voucherMinPackNotMet =
      'This voucher needs a larger pack in your bag (for example 1 kg or more).';

  /// Order tracking (customer)
  static String orderNumber(String id) => 'Order #$id';
  static const currentStatusLabel = 'CURRENT STATUS';
  static String arrivingInMinutes(int minutes) =>
      'Arriving in $minutes mins';
  static const sourceLabel = 'SOURCE';
  static const destinationLabel = 'DESTINATION';
  static const orderTrackSourceName = 'Wild Forest Co.';
  static const orderTrackDestinationName = 'Home (Apt 4B)';
  static const youMarker = 'YOU';
  static const orderTrackCourierName = 'Marcus Thorne';
  static const orderTrackCourierMeta = '4.9 (1.2k deliveries)';
  static const chatCourierSoon = 'Chat will open when connected.';
  static const callCourierSoon = 'Calling rider…';
  static const timelineOrderPlaced = 'Order Placed';
  static const timelineOrderPlacedDetail =
      '11:42 AM · We\'ve received your order';
  static const timelinePreparing = 'Preparing Your Mushrooms';
  static const timelinePreparingDetail =
      '11:45 AM · Bhoomise is packing the spores';
  static const timelineOutForDelivery = 'Out for Delivery';
  static const timelineOutForDeliveryDetail =
      '11:58 AM · Marcus is on the way';
  static const timelineDelivered = 'Delivered';
  static const timelineDeliveredDetail = 'Estimated 12:15 PM';
  static const shareTrackingLink = 'Share Tracking Link';
  static const shareTrackingReady = 'Tracking link copied to clipboard.';
  static const homeSubtitle =
      'Real-time inventory, variants, and orders for suppliers, stores, and customers.';

  static const signIn = 'Sign in';
  static const signUp = 'Sign up';
  static const signOut = 'Sign out';
  static const account = 'Account';
  static const savedAddresses = 'Saved addresses';
  static const savedAddressesCardSubtitle =
      'Home, work & other spots — quick checkout';
  static const selectDeliveryAddress = 'Select Delivery Address';
  static const selectDeliverySubtitle =
      'Choose where you want your curated harvest delivered.';
  static const deliverHerePlaceOrder = 'Deliver Here & Place Order';
  static const logisticsPurity = 'LOGISTICS PURITY';
  static const freshnessScoreHigh = '98% FRESHNESS SCORE';
  static const logisticsPurityCaption =
      'Deliveries within Portland are optimized via carbon-neutral fungal-spore routes.';
  static const addNewAddressTitle = 'Add New Address';
  static const phoneLoginSubtitle =
      'Enter your 10-digit mobile number. We will send a one-time code via SMS.';
  static const phoneSignupSubtitle =
      'Create your Bhoomise account. We will verify your number with a one-time SMS code.';
  static const mobileNumber = 'Mobile number';
  static const enterValidMobile = 'Enter a valid 10-digit mobile number';
  /// Firebase Phone Auth on Android uses Play Integrity (Console disclosure). Shown under login footer.
  static const playIntegrityNoticeLead =
      'SMS verification on Android uses Google\'s Play Integrity API. ';
  static const playIntegrityNoticeLink = 'Learn more';
  /// Google Play Integrity docs (Terms / policy references are linked from there).
  static final Uri playIntegrityOverviewUri =
      Uri.parse('https://developer.android.com/google/play/integrity/overview');

  static const sendOtp = 'Send OTP';
  static const verifyOtp = 'Verify OTP';
  static const verifyOtpLogin = 'Verify & sign in';
  static const verifyOtpSignup = 'Verify & continue';
  /// OTP screen primary action (Figma).
  static const verifyAndProceed = 'Verify & Proceed';
  static const verifyPhone = 'Verify Phone';
  static const smsCode = 'SMS code';
  static const enterSixDigit = 'Enter the 6-digit code';
  static String otpInstructionSixDigit(String displayPhone) =>
      'Enter the 6-digit code sent to $displayPhone';
  static const timeRemaining = 'TIME REMAINING';
  static const resendCode = 'Resend Code';
  static const securityStrength = 'SECURITY STRENGTH';
  static const securityHigh = 'High';
  static const termsOfService = 'Terms of Service';
  static const privacyPolicy = 'Privacy Policy';
  static const verifyAndContinue = 'Verify & continue';
  static const resendOtp = 'Resend OTP';
  static const error = 'Error';
  static const missingPhoneSession =
      'Session expired. Go back and enter your number again.';
  static const otpResent = 'A new code has been sent.';

  static String otpSentTo(String phoneE164) =>
      'Enter the code sent to $phoneE164';

  static const completeProfile = 'Complete profile';
  static const editProfile = 'Edit profile';
  static const signupProfileSubtitle =
      'Add your name so we can personalize orders and deliveries.';
  static const editProfileSubtitle = 'Update your account details.';
  static const fullName = 'Full name';
  static const emailOptional = 'Email (optional)';
  static const enterName = 'Please enter your name';
  static const continueLabel = 'Continue';
  static const save = 'Save';

  static const addAddress = 'Add address';
  static const editAddress = 'Edit address';
  static const saveAddress = 'Save address';
  static const noSavedAddresses =
      'Save a delivery address for faster checkout — like quick-commerce apps.';
  static const addressFormHint =
      'Flat / house, street, landmark, and correct pincode help riders find you.';
  static const addressType = 'Save as';
  static const labelHome = 'Home';
  static const labelWork = 'Work';
  static const labelOther = 'Other';
  static const recipientName = 'Recipient name';
  static const phone = 'Phone';
  static const addressLine1 = 'Address line 1';
  static const addressLine2 = 'Address line 2 (optional)';
  static const landmark = 'Landmark';
  static const city = 'City';
  static const state = 'State';
  static const pincode = 'PIN code';
  static const required = 'Required';
  static const validPhone = 'Enter a valid phone number';
  static const validPincode = 'Enter a 6-digit PIN';
  static const saveAsDefaultAddress = 'Save as default delivery address';
  static const signInToSaveAddress =
      'Sign in with your phone to save delivery addresses.';
  static const addressSaveFailed =
      'Could not save address. Check your connection and try again.';
  static const defaultLabel = 'Default';
  static const setAsDefault = 'Set as default';
  static const deleteAddress = 'Remove address?';
  static const deleteAddressConfirm =
      'This address will be removed from your saved list.';
  static const cancel = 'Cancel';
  static const delete = 'Delete';

  static String greeting(String? name) {
    if (name == null || name.isEmpty) return 'Welcome';
    return 'Hi, $name';
  }

  static const homeSearchHint = 'Search mushrooms, powders, or vendors...';
  static const deliverToLabel = 'DELIVER TO';
  static const deliverToCityLine1 = 'Bengaluru,';
  static const deliverToCityLine2 = 'KA';
  /// Single-line city (Figma reference).
  static const deliverToCitySingle = 'New York, NY';
  static const deliverToFallbackArea = 'Set delivery area';
  static const deliverToFallbackCity = 'Add address for accurate ETA';
  static const offlineTryAgain = 'No internet connection';
  static const useCurrentLocation = 'Use current location';
  static const locatingPleaseWait = 'Finding your location…';
  static const homeCategoriesTitle = 'Categories';
  static const homeCategoriesViewAll = 'View All';
  static const homeFreshArrivalsTitle = 'Fresh Harvest Today';
  static const homeFreshHarvestSeeAll = 'See all';
  static const homeSeeMap = 'See Map';
  static const homeHeroLine =
      'Farm-fresh produce with live stock — order in minutes.';
  static const homeQuickShopTitle = 'Shop';
  static const homeShopTileTitle = 'Browse catalogue';
  static const homeShopTileSubtitle = '200g · 500g · 1kg variants';
  static const homeCartTileTitle = 'Your basket';
  static const homeCartTileSubtitle = 'Review items & totals';
  static const homeAddressesSubtitle =
      'Home, work & other spots for delivery';

  /// Partner hub (store / admin prototypes)
  static const partnerHubTitle = 'Partner hub';
  static const partnerHubSubtitle =
      'Inventory, quick sale, and supply — role-based tools';
  static const storeInventoryTitle = 'Inventory dashboard';
  static const storeInventorySubtitle = 'Stock by variant · low / out alerts';
  static const quickSaleTitle = 'Quick sale & sync';
  static const quickSaleSubtitle = 'Log offline sales · push to central stock';
  static const adminSupplyTitle = 'Global supply';
  static const adminSupplySubtitle = 'All stores · fill rate & alerts';
  static const supplyOrdersTitle = 'Supply orders';
  static const supplyOrdersSubtitle = 'B2B replenishment to stores';
}
