// lib/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'core/di/injector.dart';
import 'shared/theme/app_theme.dart';
import 'shared/pages/splash_page.dart';
import 'shared/locale/locale_cubit.dart';
import 'l10n/app_localizations.dart';
import 'features/mapas/presentation/bloc/mapas_bloc.dart';
import 'features/ubicacion/presentation/bloc/ubicacion_bloc.dart';
import 'features/mapas/presentation/pages/map_page.dart';
import 'features/ubicacion/presentation/pages/location_page.dart';
import 'features/campus/presentation/pages/campus_home_page.dart';

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/map',
      builder: (context, state) => const CampusHomePage(),
      routes: [
        GoRoute(
          path: 'building/:buildingId',
          builder: (context, state) {
            final buildingId = state.pathParameters['buildingId']!;
            return MapPage(buildingId: buildingId);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/location',
      builder: (context, state) => const LocationPage(),
    ),
  ],
);

class ElMapitaApp extends StatelessWidget {
  const ElMapitaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<MapasBloc>()),
        BlocProvider(create: (_) => getIt<UbicacionBloc>()),
        BlocProvider(create: (_) => getIt<LocaleCubit>()),
      ],
      child: BlocBuilder<LocaleCubit, Locale>(
        builder: (context, locale) {
          return MaterialApp.router(
            title: 'El Mapita UTB',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            locale: locale,
            supportedLocales: LocaleCubit.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
