import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wg_app/core/theme_mode_provider.dart';

Future<ProviderContainer> _containerWith(Map<String, Object> stored) async {
  SharedPreferences.setMockInitialValues(stored);
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('follows the system until the user picks a mode', () async {
    final container = await _containerWith({});
    expect(container.read(themeModeProvider), ThemeMode.system);
  });

  test('the chosen mode is stored and read back on the next start', () async {
    final container = await _containerWith({});
    await container.read(themeModeProvider.notifier).select(ThemeMode.dark);
    expect(container.read(themeModeProvider), ThemeMode.dark);

    final preferences = await SharedPreferences.getInstance();
    final restarted = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(restarted.dispose);
    expect(restarted.read(themeModeProvider), ThemeMode.dark);
  });

  test('an unknown stored value falls back to the system mode', () async {
    final container = await _containerWith({'theme_mode': 'sepia'});
    expect(container.read(themeModeProvider), ThemeMode.system);
  });

  test('without storage the choice still applies', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(themeModeProvider.notifier).select(ThemeMode.light);
    expect(container.read(themeModeProvider), ThemeMode.light);
  });
}
