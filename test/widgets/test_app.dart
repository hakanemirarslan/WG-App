import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wg_app/core/theme.dart';
import 'package:wg_app/l10n/app_localizations.dart';

/// Pumps [child] the way the app shows it: app theme, localizations (Turkish by
/// default) and a Riverpod scope. A phone-sized window so forms fit without scrolling.
Future<void> pumpTestApp(WidgetTester tester, Widget child, {Locale locale = const Locale('tr')}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(430, 1400);
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: buildLightTheme(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );
}

/// The localized strings for [locale], to compare against what the widgets show.
Future<AppLocalizations> l10nFor(Locale locale) => AppLocalizations.delegate.load(locale);
