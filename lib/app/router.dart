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
import '../../features/budget/screens/budget_screen.dart';
import '../../features/cart/screens/cart_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/nearby_supermarket/screens/map_screen.dart';
import '../../features/notification/screens/notification_center_screen.dart';
import '../../features/product_search/screens/price_comparison_screen.dart';
import '../../features/product_search/screens/product_detail_screen.dart';
import '../../features/product_search/screens/search_screen.dart';
import '../../features/saved_products/screens/saved_products_screen.dart';
import '../../features/price_trends/screens/trend_search_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

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

    GoRoute(
      path: "/search",
      builder: (_, __) => const SearchScreen(),
    ),

    GoRoute(
      path: "/product/:itemCode",
      builder: (_, state) => ProductDetailScreen(itemCode: state.pathParameters["itemCode"]!),
    ),

    GoRoute(
      path: "/compare/:itemCode",
      builder: (_, state) => PriceComparisonScreen(itemCode: state.pathParameters["itemCode"]!),
    ),

    GoRoute(
      path: "/favourites",
      builder: (_, __) => const SavedProductsScreen(),
    ),

    GoRoute(
      path: "/notifications",
      builder: (_, __) => const NotificationCenterScreen(),
    ),

    GoRoute(
      path: "/cart",
      builder: (_, __) => const CartScreen(),
    ),

    GoRoute(
      path: "/budget",
      builder: (_, __) => const BudgetScreen(),
    ),

    GoRoute(
      path: '/price_trends',
      builder: (context, state) => const TrendSearchScreen(),
    ),

    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);