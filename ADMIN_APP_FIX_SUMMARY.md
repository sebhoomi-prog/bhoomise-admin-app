# bAdmin App - API Fix Summary

## Changes Made

### 1. App Name Updated
- Changed display name from "Bhoomise" to **"bAdmin"** across all platforms
- Updated files:
  - Android: `android/app/src/main/AndroidManifest.xml`
  - iOS: `ios/Runner/Info.plist`
  - Web: `web/index.html`, `web/manifest.json`
  - Windows: `windows/runner/main.cpp`, `windows/runner/Runner.rc`, `windows/CMakeLists.txt`
  - macOS: `macos/Runner/Configs/AppInfo.xcconfig`, `macos/Runner.xcodeproj/project.pbxproj`
  - Linux: `linux/CMakeLists.txt`, `linux/runner/my_application.cc`
  - Flutter app: `lib/core/constants/app_strings.dart`
  - Test: `test/widget_test.dart`

### 2. Login Screen - Admin Only
✅ **Already implemented** - The current implementation uses a simple BLoC-based login page (`lib/pages/login/login_page.dart`) that is admin-only by default.
- No role selector is shown
- Automatically uses 'admin' role when calling verify OTP API
- Clean, minimal UI focused on phone OTP authentication

### 3. API Configuration Fixed
**Updated**: `lib/common/config/app_config.dart`

**Before**:
```dart
defaultValue: 'https://bhoomise.tech',  // Missing /api suffix
```

**After**:
```dart
defaultValue: 'https://bhoomise.tech/api',  // Matches customer app
```

**Why**: The customer app uses `https://bhoomise.tech/api` as base URL, and endpoints start with `/api/...`, resulting in final URLs like:
- `https://bhoomise.tech/api/api/auth/send-otp`
- `https://bhoomise.tech/api/api/auth/verify-otp`

This matches the Laravel backend routing structure.

## Architecture Overview

### Current Implementation (Used by main.dart)
The admin app uses a **modern, clean architecture**:

1. **State Management**: BLoC pattern (flutter_bloc)
2. **Dependency Injection**: GetIt service locator
3. **Secure Storage**: flutter_secure_storage for token persistence
4. **API Client**: Dio with custom interceptors

### Key Files Structure
```
lib/
├── bloc/auth/              # Auth BLoC (handles login/OTP/logout)
├── common/
│   ├── config/             # App configuration (API base URL)
│   └── di/                 # Dependency injection (service_locator.dart)
├── models/api/             # API request/response models
├── pages/
│   ├── login/              # Login & OTP pages
│   └── admin_dashboard/    # Dashboard after login
└── services/
    ├── api/                # API client, endpoints, interceptors
    ├── auth/               # Auth service (sendOtp, verifyOtp)
    └── session/            # Session/token management
```

## API Endpoints (Matching Customer App)

From `lib/services/api/api_endpoints.dart`:
```dart
static const sendOtp = '/api/auth/send-otp';
static const verifyOtp = '/api/auth/verify-otp';
static const me = '/api/me';
static const products = '/api/products';
static const stores = '/api/stores';
// ... etc
```

Combined with base URL `https://bhoomise.tech/api`, final URLs are:
- `POST https://bhoomise.tech/api/api/auth/send-otp`
- `POST https://bhoomise.tech/api/api/auth/verify-otp`

## Authentication Flow

### 1. Send OTP
**Request** (`lib/services/auth/auth_service.dart`):
```dart
POST /api/auth/send-otp
{
  "phone": "+919999999999"
}
```

### 2. Verify OTP
**Request**:
```dart
POST /api/auth/verify-otp
{
  "phone": "+919999999999",
  "otp": "123456",
  "role": "admin"  // Hardcoded for admin app
}
```

**Response** (`lib/models/api/auth_models.dart`):
```json
{
  "data": {
    "accessToken": "...",
    "user": {
      "id": "...",
      "phone": "...",
      "name": "...",
      "role": "admin"
    }
  }
}
```

### 3. Token Storage
- Stored securely using `flutter_secure_storage`
- Key: `badmin_api_token_v1`
- Auto-attached to API requests via `AuthTokenInterceptor`

## Testing the Fix

### Manual Testing Steps:
1. **Build & Run**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Test Login**:
   - Enter phone number: `9999999999` (or your test number)
   - Tap "Send OTP"
   - Should receive OTP via SMS
   - Enter OTP and tap "Verify & Sign in"
   - Should navigate to dashboard

3. **Verify API Calls**:
   - Check console logs (ApiLoggerInterceptor logs all requests/responses)
   - Verify URLs match: `https://bhoomise.tech/api/api/auth/...`

### Common Issues & Solutions:

**Issue**: "401 Unauthorized" on protected endpoints
- **Solution**: Check token is being saved and attached to requests

**Issue**: "Network error" or timeout
- **Solution**: Verify base URL is correct and backend is accessible

**Issue**: OTP not received
- **Solution**: Check backend SMS service configuration

## Next Steps
- Implement dashboard features (products, stores, inventory management)
- Add proper error handling and retry logic
- Add loading states and better UX feedback
- Implement admin-specific features (user management, analytics)

## Reference: Customer App
The customer app (`/Users/adityapal/StudioProjects/bhoomise/bhoomise-customer-app`) uses the same API structure and can be referenced for:
- Additional API endpoints
- Response model structures
- Error handling patterns
- UI/UX patterns

---

**Last Updated**: 2026-04-25
**Status**: ✅ Ready for testing
