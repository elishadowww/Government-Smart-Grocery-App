import 'package:go_router/go_router.dart';

import '../features/authentication/screens/forgot_password_screen.dart';
import '../features/authentication/screens/intro_screen.dart';
import '../features/authentication/screens/login_screen.dart';
import '../features/authentication/screens/register_screen.dart';
import '../features/authentication/screens/splash_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';

final appRouter = GoRouter(
  initialLocation: "/",

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
  ],
);