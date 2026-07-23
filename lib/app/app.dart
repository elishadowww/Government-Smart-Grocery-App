import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/database_service.dart';
import '../core/widgets/app_error.dart';
import '../core/widgets/app_loading.dart';
import '../providers/database_provider.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class SmartGroceryApp extends ConsumerWidget {
  const SmartGroceryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
      builder: (context, child) {
        final dbInit = ref.watch(databaseInitProvider);
        return dbInit.when(
          data: (_) => child ?? const SizedBox.shrink(),
          loading: () => const AppLoading(message: 'Preparing local database...'),
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
