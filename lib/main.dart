import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Initialize Supabase ────────────────────────────────────────────────────
  await Supabase.initialize(
    url:      AppConstants.supabaseUrl,
    anonKey:  AppConstants.supabaseAnonKey,
  );

  runApp(
    // ProviderScope is required for Riverpod
    const ProviderScope(
      child: CoachingApp(),
    ),
  );
}

class CoachingApp extends ConsumerWidget {
  const CoachingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title:             'Coaching Manager',
      theme:             AppTheme.light,
      darkTheme:         AppTheme.dark,
      themeMode:         ThemeMode.light,
      routerConfig:      router,
      debugShowCheckedModeBanner: false,
    );
  }
}
