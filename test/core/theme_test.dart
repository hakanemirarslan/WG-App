import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wg_app/core/theme.dart';

void main() {
  for (final (name, build) in [('light', buildLightTheme), ('dark', buildDarkTheme)]) {
    group('$name theme', () {
      test('builds and carries the semantic balance colours', () {
        final theme = build();
        final colors = theme.extension<AppColors>();
        expect(colors, isNotNull);
        // Owed (green) and owing (coral) must not be the same colour.
        expect(colors!.positiveContainer, isNot(colors.negativeContainer));
        expect(colors.positive, isNot(colors.negative));
      });

      test('uses soft neutral surfaces, not pure white or black', () {
        final scheme = build().colorScheme;
        expect(scheme.surface, isNot(const Color(0xFFFFFFFF)));
        expect(scheme.surface, isNot(const Color(0xFF000000)));
      });

      test('cards are rounded to 16', () {
        final shape = build().cardTheme.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(16));
      });
    });
  }

  test('light and dark use the matching brightness', () {
    expect(buildLightTheme().brightness, Brightness.light);
    expect(buildDarkTheme().brightness, Brightness.dark);
  });
}
