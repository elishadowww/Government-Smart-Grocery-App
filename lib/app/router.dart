import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/repositories/auth_repositories.dart';
import '../../features/authentication/screens/forgot_password_screen.dart';
import '../../features/authentication/screens/intro_screen.dart';
import '../../features/authentication/screens/login_screen.dart';
import '../../features/authentication/screens/privacy_policy_screen.dart';
import '../../features/authentication/screens/register_screen.dart';
import '../../features/authentication/screens/splash_screen.dart';
import '../../features/authentication/screens/terms_of_service_screen.dart';
import '../../features/authentication/screens/verify_email_screen.dart';
import '../../features/authentication/services/auth_state_notifier.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/nearby_supermarket/screens/map_screen.dart';

final _authNotifier = AuthStateNotifier();

final appRouter = GoRouter(
  initialLocation: "/",

  refreshListenable: _authNotifier,

  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;

    final location = state.uri.path;

    if (user == null) {
      if (location == "/dashboard" ||
          location == "/verify-email") {
        return "/intro";
      }

      return null;
    }

    if (AuthRepository().requiresEmailVerification) {
      if (location != "/verify-email") {
        return "/verify-email";
      }

      return null;
    }

    if (location == "/" ||
        location == "/intro" ||
        location == "/login" ||
        location == "/register" ||
        location == "/forgot" ||
        location == "/verify-email") {
      return "/dashboard";
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
      path: "/verify-email",
      builder: (_, __) => const VerifyEmailScreen(),
    ),


    GoRoute(
      path: "/terms",
      builder: (_, __) => const TermsOfServiceScreen(),
    ),

    GoRoute(
      path: "/privacy",
      builder: (_, __) => const PrivacyPolicyScreen(),
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