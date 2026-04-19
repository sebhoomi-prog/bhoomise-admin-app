/// Chosen on the login screen (Figma segmented control) and persisted after OTP.
enum AppRole {
  customer,
  /// Store / cultivator shell (vendor console).
  partner,
  /// Platform ops — supply / marketplace admin dashboard.
  admin,
}
