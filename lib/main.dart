import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/locale_provider.dart';
import 'core/router.dart';
import 'core/supabase_client.dart';
import 'core/theme.dart';
import 'l10n/app_localizations.dart';

/// Widest the app content gets on desktop browsers.
const _maxContentWidth = 640.0;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await initSupabase();
  runApp(const ProviderScope(child: MyApp()));
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
      routerConfig: router,
      // Phone-sized column on wide screens: content (and sheets/dialogs) stay centred.
      builder: (context, child) => ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: child,
          ),
        ),
      ),
    );
  }
}
