// Dependency Injection setup using get_it
// lib/core/di/injector.dart

import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import '../network/dio_client.dart';
import '../network/api_interceptors.dart';
import '../storage/local_storage.dart';
import '../storage/secure_storage.dart';
import '../platform/permission_service.dart';
import '../../features/mapas/infrastructure/api/mapas_api.dart';
import '../../features/mapas/infrastructure/storage/model_cache.dart';
import '../../features/mapas/application/load_building_use_case.dart';
import '../../features/mapas/presentation/bloc/mapas_bloc.dart';
import '../../features/ubicacion/infrastructure/platform/location_service.dart';
import '../../features/ubicacion/application/get_location_use_case.dart';
import '../../features/ubicacion/presentation/bloc/ubicacion_bloc.dart';
import '../../features/auth/infrastructure/supabase_auth_client.dart';
import '../../features/auth/application/sign_in_use_case.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

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
  
  // Platform services
  getIt.registerLazySingleton<PermissionService>(() => PermissionService());
  getIt.registerLazySingleton<LocationService>(() => LocationService());
  
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
  getIt.registerFactory<GetLocationUseCase>(() => GetLocationUseCase(
    locationService: getIt<LocationService>(),
  ));
  getIt.registerFactory<UbicacionBloc>(() => UbicacionBloc(
    getLocationUseCase: getIt<GetLocationUseCase>(),
    permissionService: getIt<PermissionService>(),
  ));
  
  // Feature: Auth
  getIt.registerLazySingleton<SupabaseAuthClient>(() => SupabaseAuthClient());
  getIt.registerFactory<SignInUseCase>(() => SignInUseCase(
    authClient: getIt<SupabaseAuthClient>(),
    secureStorage: getIt<SecureStorage>(),
  ));
  getIt.registerFactory<AuthBloc>(() => AuthBloc(
    signInUseCase: getIt<SignInUseCase>(),
    secureStorage: getIt<SecureStorage>(),
  ));
}