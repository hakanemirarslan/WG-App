import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/legacy.dart';

const supportedLocaleCodes = ['de', 'en', 'tr'];

Locale deviceLocaleOrDefault() {
  final deviceCode = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  return Locale(supportedLocaleCodes.contains(deviceCode) ? deviceCode : 'de');
}

/// The locale the app is currently rendered in. Defaults to the device
/// locale (SPEC 11) and is synced to `profiles.locale` once a user is
/// logged in; changing it here applies immediately (SPEC 12).
final appLocaleProvider = StateProvider<Locale>((ref) => deviceLocaleOrDefault());
