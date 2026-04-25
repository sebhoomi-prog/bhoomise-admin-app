import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/backend_config.dart';
import '../../core/network/api_client.dart';
import '../../core/session/app_session_service.dart';
import '../../features/auth/data/datasources/auth_api_datasource.dart';
import '../../features/auth/data/datasources/auth_firebase_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/send_phone_verification.dart';
import '../../features/auth/domain/usecases/sign_out.dart';
import '../../features/auth/domain/usecases/verify_sms_code.dart';
import '../../features/auth/domain/usecases/watch_auth_state.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';

class AuthDependencies {
  static void register() {
    Get.lazyPut<AuthRemoteDataSource>(
      () => BackendConfig.hasRestApi
          ? AuthApiDataSource(
              Get.find<ApiClient>(),
              Get.find<AppSessionService>(),
              Get.find<SharedPreferences>(),
            )
          : AuthFirebaseDataSource(),
      fenix: true,
    );
    Get.lazyPut<AuthRepository>(
      () => AuthRepositoryImpl(Get.find()),
      fenix: true,
    );
    Get.lazyPut<WatchAuthState>(
      () => WatchAuthState(Get.find()),
      fenix: true,
    );
    Get.lazyPut<SendPhoneVerification>(
      () => SendPhoneVerification(Get.find()),
      fenix: true,
    );
    Get.lazyPut<VerifySmsCode>(
      () => VerifySmsCode(Get.find()),
      fenix: true,
    );
    Get.lazyPut<SignOut>(
      () => SignOut(Get.find()),
      fenix: true,
    );

    Get.put<AuthController>(
      AuthController(
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
      ),
      permanent: true,
    );
  }
}
