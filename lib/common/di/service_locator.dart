import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../services/admin/admin_api_service.dart';
import '../../services/api/api_client.dart';
import '../../services/api/api_interceptors.dart';
import '../../services/api/dio_factory.dart';
import '../../services/auth/auth_service.dart';
import '../../services/auth/i_auth_service.dart';
import '../../services/session/i_session_service.dart';
import '../../services/session/session_service.dart';

final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Use Android-compatible options for flutter_secure_storage
  const androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );
  const storage = FlutterSecureStorage(aOptions: androidOptions);
  
  sl.registerLazySingleton<FlutterSecureStorage>(() => storage);

  final session = SessionService(sl<FlutterSecureStorage>());
  await session.load();
  sl.registerSingleton<ISessionService>(session);

  sl.registerLazySingleton<Dio>(
    () => DioFactory.create(
      interceptors: [
        InfinityFreeBypassInterceptor(),
        AuthTokenInterceptor(sl<ISessionService>()),
        ApiLoggerInterceptor(),
      ],
    ),
  );

  sl.registerLazySingleton<ApiClient>(() => ApiClient(dio: sl<Dio>()));
  sl.registerLazySingleton<IAuthService>(
    () => AuthService(sl<ApiClient>(), sl<ISessionService>()),
  );
  sl.registerLazySingleton<AdminApiService>(
    () => AdminApiService(sl<ApiClient>()),
  );

  sl.registerFactory<AuthBloc>(() => AuthBloc(sl<IAuthService>(), sl<ISessionService>()));
}

