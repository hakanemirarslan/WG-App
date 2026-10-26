import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device storage (localStorage on the web). Loaded in `main` before the first frame
/// and passed in through an override; null if the browser blocks storage.
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

/// Light / dark / follow the system. A per-device choice (phone dark, laptop light),
/// so it lives in device storage, not in the profile.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final stored = ref.watch(sharedPreferencesProvider)?.getString(_key);
    return ThemeMode.values.firstWhere((m) => m.name == stored, orElse: () => ThemeMode.system);
  }

  Future<void> select(ThemeMode mode) async {
    state = mode;
    try {
      await ref.read(sharedPreferencesProvider)?.setString(_key, mode.name);
    } catch (_) {
      // Storage blocked (e.g. private window): the choice still applies until reload.
    }
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
