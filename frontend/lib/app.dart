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
import 'features/mapas/presentation/pages/campus_model_page.dart';
import 'features/ubicacion/presentation/pages/location_page.dart';
import 'features/campus/presentation/pages/campus_home_page.dart';

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashPage(),
    ),
    // Dos pestanas que conservan su estado (el visor 3D no se recarga al
    // cambiar de pestana). El mapa 3D es la pantalla de inicio.
    StatefulShellRoute(
      builder: (context, state, shell) => _HomeShell(shell: shell),
      navigatorContainerBuilder: (context, shell, children) =>
          _SlidingBranches(index: shell.currentIndex, children: children),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/map',
              builder: (context, state) => const CampusModelPage(),
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
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/lugares',
              builder: (context, state) => const CampusHomePage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/location',
      builder: (context, state) => const LocationPage(),
    ),
  ],
);

/// Barra inferior con las dos pestañas principales: mapa 3D y lugares.
class _HomeShell extends StatelessWidget {
  final StatefulNavigationShell shell;

  const _HomeShell({required this.shell});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        // Tocar la pestaña activa vuelve a su raíz.
        onDestinationSelected: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.view_in_ar_outlined),
            selectedIcon: const Icon(Icons.view_in_ar),
            label: l10n.navMap3d,
          ),
          NavigationDestination(
            icon: const Icon(Icons.list_alt_outlined),
            selectedIcon: const Icon(Icons.list_alt),
            label: l10n.navPlaces,
          ),
        ],
      ),
    );
  }
}

/// Muestra las pestañas una junto a otra y desliza horizontalmente de una a
/// la otra. Todas siguen montadas (el visor 3D conserva su estado); la que
/// queda fuera de pantalla se oculta.
class _SlidingBranches extends StatelessWidget {
  static const Duration _duration = Duration(milliseconds: 300);

  final int index;
  final List<Widget> children;

  const _SlidingBranches({required this.index, required this.children});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: index.toDouble()),
        duration: _duration,
        curve: Curves.easeOutCubic,
        builder: (context, position, _) => Stack(
          fit: StackFit.expand,
          children: [
            for (var i = 0; i < children.length; i++)
              Offstage(
                offstage: (i - position).abs() >= 1,
                child: FractionalTranslation(
                  translation: Offset(i - position, 0),
                  child: TickerMode(
                    enabled: (i - position).abs() < 1,
                    child: children[i],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

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
