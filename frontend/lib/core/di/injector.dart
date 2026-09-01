// Dependency Injection setup using get_it
// lib/core/di/injector.dart

import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/core/network/api_interceptors.dart';
import 'package:frontend/core/storage/local_storage.dart';
import 'package:frontend/core/storage/secure_storage.dart';
import 'package:frontend/core/platform/permission_service.dart';
import 'package:frontend/core/platform/location_service.dart';
import 'package:frontend/features/mapas/infrastructure/api/mapas_api.dart';
import 'package:frontend/features/mapas/infrastructure/storage/model_cache.dart';
import 'package:frontend/features/mapas/application/load_building_use_case.dart';
import 'package:frontend/features/mapas/presentation/bloc/mapas_bloc.dart';
import 'package:frontend/features/ubicacion/domain/repositories.dart';
import 'package:frontend/features/ubicacion/infrastructure/platform/location_service_impl.dart';
import 'package:frontend/features/ubicacion/application/get_location_use_case.dart';
import 'package:frontend/features/ubicacion/presentation/bloc/ubicacion_bloc.dart';
import 'package:frontend/features/auth/domain/repositories.dart';
import 'package:frontend/features/auth/infrastructure/supabase_auth_client.dart';
import 'package:frontend/features/auth/application/sign_in_use_case.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:frontend/shared/locale/locale_cubit.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Core services
  getIt.registerLazySingleton<Dio>(() => DioClient.create());
  getIt.registerLazySingleton<ApiInterceptors>(() => ApiInterceptors());

  // Storage
  getIt.registerLazySingleton<LocalStorage>(() => LocalStorage());
  getIt.registerLazySingleton<SecureStorage>(() => SecureStorage());
  await getIt<LocalStorage>().init();
  await getIt<SecureStorage>().init();
  getIt.registerLazySingleton<LocaleCubit>(() => LocaleCubit(getIt<LocalStorage>()));

  // Platform services
  getIt.registerLazySingleton<PermissionService>(() => PermissionService());
  getIt.registerLazySingleton<LocationService>(
    () => LocationService(getIt<PermissionService>()),
  );

  // Feature: Mapas
  getIt.registerLazySingleton<MapasApi>(() => MapasApi(getIt<Dio>()));
  getIt.registerLazySingleton<ModelCache>(() => ModelCache(getIt<LocalStorage>()));
  getIt.registerFactory<LoadBuildingUseCase>(() => LoadBuildingUseCase(
    api: getIt<MapasApi>(),
    cache: getIt<ModelCache>(),
  ));
  getIt.registerFactory<MapasBloc>(() => MapasBloc(
    loadBuildingUseCase: getIt<LoadBuildingUseCase>(),
  ));

  // Feature: Ubicacion
  getIt.registerLazySingleton<LocationRepository>(
    () => LocationServiceImpl(getIt<LocationService>()),
  );
  getIt.registerFactory<GetLocationUseCase>(() => GetLocationUseCase(
    repository: getIt<LocationRepository>(),
  ));
  getIt.registerFactory<UbicacionBloc>(() => UbicacionBloc(
    getLocationUseCase: getIt<GetLocationUseCase>(),
    permissionService: getIt<PermissionService>(),
  ));

  // Feature: Auth
  getIt.registerLazySingleton<SupabaseAuthClient>(
    () => SupabaseAuthClient(getIt<SecureStorage>()),
  );
  getIt.registerLazySingleton<AuthRepository>(() => getIt<SupabaseAuthClient>());
  getIt.registerFactory<SignInUseCase>(() => SignInUseCase(
    authClient: getIt<AuthRepository>(),
    secureStorage: getIt<SecureStorage>(),
  ));
  getIt.registerFactory<SignUpUseCase>(() => SignUpUseCase(
    authClient: getIt<AuthRepository>(),
    secureStorage: getIt<SecureStorage>(),
  ));
  getIt.registerFactory<GetCurrentUserUseCase>(
    () => GetCurrentUserUseCase(getIt<AuthRepository>()),
  );
  getIt.registerFactory<SignOutUseCase>(
    () => SignOutUseCase(getIt<AuthRepository>()),
  );
  getIt.registerFactory<AuthBloc>(() => AuthBloc(
    signInUseCase: getIt<SignInUseCase>(),
    signUpUseCase: getIt<SignUpUseCase>(),
    getCurrentUserUseCase: getIt<GetCurrentUserUseCase>(),
    signOutUseCase: getIt<SignOutUseCase>(),
    secureStorage: getIt<SecureStorage>(),
  ));
}
