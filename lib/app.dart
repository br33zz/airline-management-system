import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/airline_models.dart';
import 'screens/entity_detail_screen.dart';
import 'screens/entity_form_screen.dart';
import 'screens/entity_list_screen.dart';

EntityKind _kind(GoRouterState state) =>
    EntityKindUi.tryParse(state.pathParameters['entity']) ?? EntityKind.flights;

final router = GoRouter(
  initialLocation: '/flights',
  routes: [
    GoRoute(path: '/', redirect: (_, __) => '/flights'),
    GoRoute(
      path: '/:entity/new',
      builder: (_, state) => EntityFormScreen(kind: _kind(state)),
    ),
    GoRoute(
      path: '/:entity/:id/edit',
      builder: (_, state) => EntityFormScreen(
        kind: _kind(state),
        id: int.tryParse(state.pathParameters['id'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/:entity/:id',
      builder: (_, state) => EntityDetailScreen(
        kind: _kind(state),
        id: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
      ),
    ),
    GoRoute(
      path: '/:entity',
      builder: (_, state) =>
          EntityListScreen(kind: _kind(state), uri: state.uri),
    ),
  ],
);

class AirlineApp extends StatelessWidget {
  const AirlineApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    debugShowCheckedModeBanner: false,
    title: 'Авиакомпания',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff155eef),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xfff5f7fb),
      cardTheme: const CardThemeData(elevation: 0),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
    ),
    routerConfig: router,
  );
}
