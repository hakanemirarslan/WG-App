import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/locale_provider.dart';
import 'core/router.dart';
import 'core/supabase_client.dart';
import 'core/theme.dart';
import 'l10n/app_localizations.dart';

/// Riverpod 3 retries a failed provider up to 10 times (about 40 seconds) and shows
/// "loading" meanwhile, which hides our error screens. One quick retry covers a
/// network blip; after that the error screen with its retry button appears.
Duration? _retry(int retryCount, Object error) =>
    retryCount >= 1 ? null : const Duration(milliseconds: 600);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await initSupabase();
  runApp(const ProviderScope(retry: _retry, child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(appLocaleProvider);

    return MaterialApp.router(
      title: 'WG App',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Full window width: each page limits its own content (core/layout.dart), and the
      // group tabs switch to a side rail on wide screens.
      routerConfig: router,
    );
  }
}
