import Flutter
import UIKit

// Phone Auth on real iOS devices: Firebase uses APNs (silent push) for app verification in
// production/release. Required: (1) Push Notifications capability (Runner entitlements),
// (2) APNs Auth Key uploaded in Firebase Console → Project settings → Cloud Messaging,
// (3) Apple Team ID in Firebase iOS app settings, (4) GoogleService-Info.plist must include
// REVERSED_CLIENT_ID and that value must appear in Info.plist → URL Types (re-download plist
// from Firebase if REVERSED_CLIENT_ID is missing).

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Registers for APNs so Firebase Auth can complete phone verification on device.
    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
