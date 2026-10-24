import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

/// Central look of the app: calm teal, soft neutral surfaces, rounded shapes.
/// Screens read colours from `Theme.of(context).colorScheme` and [AppColors];
/// no hard-coded colours elsewhere.
const _fontFamily = 'Inter';

const _seed = Color(0xFF0E9F8E);

// Soft neutrals: no pure white/black. Cards sit one step above the page.
const _lightSurfaces = (
  surface: Color(0xFFF6F7F6),
  lowest: Color(0xFFFFFFFF),
  low: Color(0xFFF0F2F1),
  container: Color(0xFFEBEEED),
  high: Color(0xFFE5E9E8),
  highest: Color(0xFFDFE4E3),
  onSurface: Color(0xFF14191A),
  outlineVariant: Color(0xFFDCE2E0),
);

const _darkSurfaces = (
  surface: Color(0xFF14181A),
  lowest: Color(0xFF101416),
  low: Color(0xFF1A1F21),
  container: Color(0xFF1E2427),
  high: Color(0xFF262D30),
  highest: Color(0xFF2E3639),
  onSurface: Color(0xFFE4E9E8),
  outlineVariant: Color(0xFF2F3739),
);

/// App-specific semantic colours that [ColorScheme] has no role for: money you
/// are owed (green) and money you owe (coral). They only mean that, nowhere else.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.positive,
    required this.positiveContainer,
    required this.onPositiveContainer,
    required this.negative,
    required this.negativeContainer,
    required this.onNegativeContainer,
  });

  /// Strong tone for text/icons on the normal surface.
  final Color positive;
  final Color positiveContainer;
  final Color onPositiveContainer;
  final Color negative;
  final Color negativeContainer;
  final Color onNegativeContainer;

  static const light = AppColors(
    positive: Color(0xFF2E8B57),
    positiveContainer: Color(0xFFD9F2E3),
    onPositiveContainer: Color(0xFF0B3D22),
    negative: Color(0xFFC94534),
    negativeContainer: Color(0xFFFFE1DC),
    onNegativeContainer: Color(0xFF5C1109),
  );

  static const dark = AppColors(
    positive: Color(0xFF6FD39A),
    positiveContainer: Color(0xFF14452B),
    onPositiveContainer: Color(0xFFC6F0D6),
    negative: Color(0xFFFF8A7A),
    negativeContainer: Color(0xFF5A1D16),
    onNegativeContainer: Color(0xFFFFD9D3),
  );

  static AppColors of(BuildContext context) => Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith({
    Color? positive,
    Color? positiveContainer,
    Color? onPositiveContainer,
    Color? negative,
    Color? negativeContainer,
    Color? onNegativeContainer,
  }) {
    return AppColors(
      positive: positive ?? this.positive,
      positiveContainer: positiveContainer ?? this.positiveContainer,
      onPositiveContainer: onPositiveContainer ?? this.onPositiveContainer,
      negative: negative ?? this.negative,
      negativeContainer: negativeContainer ?? this.negativeContainer,
      onNegativeContainer: onNegativeContainer ?? this.onNegativeContainer,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      positive: Color.lerp(positive, other.positive, t)!,
      positiveContainer: Color.lerp(positiveContainer, other.positiveContainer, t)!,
      onPositiveContainer: Color.lerp(onPositiveContainer, other.onPositiveContainer, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      negativeContainer: Color.lerp(negativeContainer, other.negativeContainer, t)!,
      onNegativeContainer: Color.lerp(onNegativeContainer, other.onNegativeContainer, t)!,
    );
  }
}

ThemeData buildLightTheme() => _build(Brightness.light, _lightSurfaces, AppColors.light);

ThemeData buildDarkTheme() => _build(Brightness.dark, _darkSurfaces, AppColors.dark);

ThemeData _build(
  Brightness brightness,
  ({
    Color surface,
    Color lowest,
    Color low,
    Color container,
    Color high,
    Color highest,
    Color onSurface,
    Color outlineVariant,
  })
  surfaces,
  AppColors colors,
) {
  // The seed produces the teal tonal palette (primary, containers); we only swap
  // in our own neutral surfaces on top of it.
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness).copyWith(
    surface: surfaces.surface,
    surfaceContainerLowest: surfaces.lowest,
    surfaceContainerLow: surfaces.low,
    surfaceContainer: surfaces.container,
    surfaceContainerHigh: surfaces.high,
    surfaceContainerHighest: surfaces.highest,
    onSurface: surfaces.onSurface,
    outlineVariant: surfaces.outlineVariant,
  );

  final flex = brightness == Brightness.light
      ? FlexThemeData.light(
          colorScheme: scheme,
          scaffoldBackground: scheme.surface,
          fontFamily: _fontFamily,
          subThemesData: _subThemes,
          extensions: [colors],
        )
      : FlexThemeData.dark(
          colorScheme: scheme,
          scaffoldBackground: scheme.surface,
          fontFamily: _fontFamily,
          subThemesData: _subThemes,
          extensions: [colors],
        );

  // Titles are bold so hierarchy reads without relying on size alone.
  final text = flex.textTheme;
  final textTheme = text.copyWith(
    headlineMedium: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
    headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
    titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
  );

  return flex.copyWith(
    textTheme: textTheme,
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 2,
      highlightElevation: 4,
      extendedTextStyle: textTheme.labelLarge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      elevation: 0,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStatePropertyAll(
        textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: TextStyle(color: scheme.onInverseSurface, fontFamily: _fontFamily),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

// Radii: cards 16, buttons/inputs 12, sheets 24.
const _subThemes = FlexSubThemesData(
  defaultRadius: 12,
  cardRadius: 16,
  cardElevation: 0,
  fabRadius: 16,
  fabUseShape: true,
  bottomSheetRadius: 24,
  dialogRadius: 20,
  inputDecoratorIsFilled: true,
  inputDecoratorBorderType: FlexInputBorderType.outline,
  inputDecoratorRadius: 12,
  interactionEffects: true,
  useMaterial3Typography: true,
);
