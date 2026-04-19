import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/backend_config.dart';
import '../../core/network/mock_asset_client.dart';
import '../../features/profile/data/datasources/profile_asset_datasource.dart';
import '../../features/profile/data/datasources/profile_local_datasource.dart';
import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/get_user_profile.dart';
import '../../features/profile/domain/usecases/resolve_post_auth_destination.dart';
import '../../features/profile/domain/usecases/save_user_profile.dart';

class ProfileDependencies {
  static void register() {
    Get.lazyPut<ProfileRemoteDataSource>(
      () {
        if (BackendConfig.useMockApiAssets) {
          return ProfileAssetDataSource(
            Get.find<SharedPreferences>(),
            Get.find<MockAssetClient>(),
          );
        }
        return ProfileLocalDataSource(Get.find<SharedPreferences>());
      },
      fenix: true,
    );
    Get.lazyPut<ProfileRepository>(
      () => ProfileRepositoryImpl(Get.find()),
      fenix: true,
    );
    Get.lazyPut<GetUserProfile>(
      () => GetUserProfile(Get.find()),
      fenix: true,
    );
    Get.lazyPut<SaveUserProfile>(
      () => SaveUserProfile(Get.find()),
      fenix: true,
    );
    Get.lazyPut<ResolvePostAuthDestination>(
      () => ResolvePostAuthDestination(Get.find()),
      fenix: true,
    );
  }
}
