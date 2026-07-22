import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/registro_screen.dart';
import '../../features/tandas/presentation/screens/home_screen.dart';
import '../../features/tandas/presentation/screens/crear_tanda_screen.dart';
import '../../features/tandas/presentation/screens/tanda_detalle_screen.dart';
import '../../features/tandas/presentation/screens/miembros_lista_screen.dart';
import '../../features/tandas/presentation/screens/agregar_miembro_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/registro',
      builder: (context, state) => const RegistroScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/tandas/crear',
      builder: (context, state) => const CrearTandaScreen(),
    ),
    GoRoute(
      path: '/tandas/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return TandaDetalleScreen(id: id);
      },
    ),
    GoRoute(
      path: '/tandas/:id/miembros',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return MiembrosListaScreen(id: id);
      },
    ),
    GoRoute(
      path: '/tandas/:id/miembros/agregar',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return AgregarMiembroScreen(id: id);
      },
    ),
  ],
);
