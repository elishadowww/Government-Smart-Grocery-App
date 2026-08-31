import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../providers/locale_provider.dart';
import '../core/services/database_service.dart';
import '../core/widgets/app_error.dart';
import '../core/widgets/app_loading.dart';
import '../core/widgets/no_internet_screen.dart';
import '../providers/connectivity_provider.dart';
import '../providers/database_provider.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class SmartGroceryApp extends ConsumerWidget {
  const SmartGroceryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
      locale: locale,
      supportedLocales: const [
        Locale('en'), // English
        Locale('ms'), // Bahasa Melayu
        Locale('zh'), // Chinese
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final dbInit = ref.watch(databaseInitProvider);
        return dbInit.when(
          data: (_) {
            final isOnline = ref.watch(isOnlineProvider).value ?? true;
            if (!isOnline) return const NoInternetScreen();
            return child ?? const SizedBox.shrink();
          },
          loading: () {
            final progress = ref.watch(databaseCopyProgressProvider).value;
            final message = progress == null
                ? 'Preparing local database...'
                : 'Preparing local database — first launch only\n'
                    '${(progress * 100).toStringAsFixed(0)}%\n\n'
                    'This can take a few minutes the first time.';
            return AppLoading(message: message);
          },
          error: (error, _) => AppError(
            message: error is DatabaseNotAvailableException
                ? error.message
                : 'Failed to open the local database:\n$error',
            onRetry: () => ref.invalidate(databaseInitProvider),
          ),
        );
      },
    );
  }
}
