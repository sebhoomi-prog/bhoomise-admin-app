import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/backend_config.dart';
import '../../core/location/delivery_location_controller.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_interceptors.dart';
import '../../core/network/connectivity_sync_service.dart';
import '../../core/network/dio_factory.dart';
import '../../core/network/mock_asset_client.dart';
import '../../core/session/app_session_service.dart';
import '../../core/storage/local_storage.dart';
import '../../shared/firebase/repositories/shared_app_firestore_repository.dart';
import '../../shared/firebase/repositories/shared_catalog_firestore_repository.dart';
import '../../shared/firebase/repositories/shared_coupon_firestore_repository.dart';

/// Registers [ApiClient] for a live base URL, or [MockAssetClient] for `assets/mock_api/`.
class CoreDependencies {
  static void register() {
    Get.put<AppSessionService>(
      AppSessionService(Get.find<SharedPreferences>()),
      permanent: true,
    );
    Get.put<ConnectivitySyncService>(
      ConnectivitySyncService(Get.find<LocalStorage>()),
      permanent: true,
    );
    Get.put<DeliveryLocationController>(
      DeliveryLocationController(Get.find<SharedPreferences>()),
      permanent: true,
    );
    Get.put<SharedAppFirestoreRepository>(
      SharedAppFirestoreRepository(),
      permanent: true,
    );
    Get.put<SharedCatalogFirestoreRepository>(
      SharedCatalogFirestoreRepository(),
      permanent: true,
    );
    Get.put<SharedCouponFirestoreRepository>(
      SharedCouponFirestoreRepository(),
      permanent: true,
    );
    if (BackendConfig.hasRestApi) {
      Get.lazyPut<ApiClient>(
        () => ApiClient(
          dio: DioFactory.create(
            baseUrl: BackendConfig.apiBaseUrl.trim(),
            extraInterceptors: [
              AuthBearerInterceptor(
                () => Get.find<AppSessionService>().apiToken,
              ),
              ApiLoggerInterceptor(),
            ],
          ),
        ),
        fenix: true,
      );
    } else {
      // Eager register so asset-backed datasources always resolve (lazyPut + isRegistered is fragile).
      Get.put<MockAssetClient>(MockAssetClient(), permanent: true);
    }
  }
}
