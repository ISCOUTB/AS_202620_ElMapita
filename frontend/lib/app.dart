// lib/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'core/di/injector.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/mapas/presentation/bloc/mapas_bloc.dart';
import 'features/ubicacion/presentation/bloc/ubicacion_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/mapas/presentation/pages/map_page.dart';
import 'features/mapas/presentation/pages/building_list_page.dart';
import 'features/ubicacion/presentation/pages/location_page.dart';

final _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final authState = context.read<AuthBloc>().state;
    final isLoggedIn = authState is AuthAuthenticated;
    final isAuthRoute = state.matchedLocation.startsWith('/login') || state.matchedLocation.startsWith('/register');
    
    if (!isLoggedIn && !isAuthRoute) {
      return '/login';
    }
    if (isLoggedIn && isAuthRoute) {
      return '/map';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/map',
      builder: (context, state) => const BuildingListPage(),
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
        BlocProvider(create: (_) => getIt<AuthBloc>()..add(AuthCheckStatus())),
        BlocProvider(create: (_) => getIt<MapasBloc>()),
        BlocProvider(create: (_) => getIt<UbicacionBloc>()),
      ],
      child: MaterialApp.router(
        title: 'El Mapita UTB',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: _router,
      ),
    );
  }
}