import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/screens/forgot_password_screen.dart';
import '../../features/authentication/screens/intro_screen.dart';
import '../../features/authentication/screens/login_screen.dart';
import '../../features/authentication/screens/register_screen.dart';
import '../../features/authentication/screens/splash_screen.dart';
import '../../features/authentication/services/auth_state_notifier.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/nearby_supermarket/screens/map_screen.dart';

final _authNotifier = AuthStateNotifier();

final appRouter = GoRouter(
  initialLocation: "/",

  refreshListenable: _authNotifier,

  redirect: (context, state) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;

    final location = state.uri.path;

    const authRoutes = {
      "/",
      "/intro",
      "/login",
      "/register",
      "/forgot",
    };

    if (loggedIn && authRoutes.contains(location)) {
      return "/dashboard";
    }

    if (!loggedIn && location == "/dashboard") {
      return "/intro";
    }

    return null;
  },

  routes: [
    GoRoute(
      path: "/",
      builder: (_, __) => const SplashScreen(),
    ),

    GoRoute(
      path: "/intro",
      builder: (_, __) => const IntroScreen(),
    ),

    GoRoute(
      path: "/login",
      builder: (_, __) => const LoginScreen(),
    ),

    GoRoute(
      path: "/register",
      builder: (_, __) => const RegisterScreen(),
    ),

    GoRoute(
      path: "/forgot",
      builder: (_, __) => const ForgotPasswordScreen(),
    ),

    GoRoute(
      path: "/dashboard",
      builder: (_, __) => const DashboardScreen(),
    ),

    GoRoute(
      path: "/nearby",
      builder: (_, __) => const MapScreen(),
    ),
  ],
);