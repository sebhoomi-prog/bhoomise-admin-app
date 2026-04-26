// Firebase Phone Auth on Android (Play Integrity): register signing keys in Firebase Console
// (Project settings → bhoomise Android app → Add fingerprint) or you see
// "Invalid app info in play_integrity_token" and `oauth_client` stays empty in google-services.json.
//
// 1) `cd android && ./gradlew signingReport` — copy SHA-1 and SHA-256 for the build you use
//    (debug uses ~/.android/debug.keystore while release uses your upload keystore).
// 2) Paste into Firebase, save, download a fresh `google-services.json` into `android/app/`.
// 3) Play installs: also add fingerprints from Play Console → App integrity (app signing key).

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.bhoomise.admin"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.bhoomise.admin"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}
dependencies {
    implementation("androidx.credentials:credentials:1.6.0")
    implementation("androidx.credentials:credentials-play-services-auth:1.6.0")
    implementation("com.google.android.libraries.identity.googleid:googleid:1.2.0")
}

flutter {
    source = "../.."
}
