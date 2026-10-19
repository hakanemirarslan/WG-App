import 'package:flutter/material.dart';

/// Central look of the app (warm, rounded, flat). Screens read colours from
/// `Theme.of(context).colorScheme` and [AppColors]; no hard-coded colours elsewhere.
const _fontFamily = 'Nunito';

const _lightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFFC2603B),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFF7DCCF),
  onPrimaryContainer: Color(0xFF4A1F0D),
  secondary: Color(0xFFE3A93B),
  onSecondary: Color(0xFF2B2118),
  secondaryContainer: Color(0xFFFBEBC4),
  onSecondaryContainer: Color(0xFF4A3500),
  tertiary: Color(0xFF4F7F5B),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFD8EAD9),
  onTertiaryContainer: Color(0xFF17331E),
  error: Color(0xFFB3402F),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFF9DDD7),
  onErrorContainer: Color(0xFF410E08),
  surface: Color(0xFFFBF6EE),
  onSurface: Color(0xFF2B2118),
  onSurfaceVariant: Color(0xFF6B5E52),
  outline: Color(0xFF9C8E80),
  outlineVariant: Color(0xFFE6DACB),
  surfaceContainerLowest: Color(0xFFFFFDF9),
  surfaceContainerLow: Color(0xFFF6EFE3),
  surfaceContainer: Color(0xFFF3EADB),
  surfaceContainerHigh: Color(0xFFEFE5D4),
  surfaceContainerHighest: Color(0xFFEBDFCD),
  inverseSurface: Color(0xFF3B3128),
  onInverseSurface: Color(0xFFFBF6EE),
  inversePrimary: Color(0xFFE8956F),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
);

const _darkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFE8956F),
  onPrimary: Color(0xFF3B1604),
  primaryContainer: Color(0xFF7A3519),
  onPrimaryContainer: Color(0xFFF7DCCF),
  secondary: Color(0xFFEBC166),
  onSecondary: Color(0xFF3A2A00),
  secondaryContainer: Color(0xFF5A4300),
  onSecondaryContainer: Color(0xFFFBEBC4),
  tertiary: Color(0xFF8DBF98),
  onTertiary: Color(0xFF0F2A17),
  tertiaryContainer: Color(0xFF2F5A3B),
  onTertiaryContainer: Color(0xFFD8EAD9),
  error: Color(0xFFF2A093),
  onError: Color(0xFF5A1208),
  errorContainer: Color(0xFF7D2A1D),
  onErrorContainer: Color(0xFFF9DDD7),
  surface: Color(0xFF1E1A16),
  onSurface: Color(0xFFF1E8DC),
  onSurfaceVariant: Color(0xFFCDBFAF),
  outline: Color(0xFFA39583),
  outlineVariant: Color(0xFF4A4137),
  surfaceContainerLowest: Color(0xFF17130F),
  surfaceContainerLow: Color(0xFF242019),
  surfaceContainer: Color(0xFF2A251E),
  surfaceContainerHigh: Color(0xFF322C24),
  surfaceContainerHighest: Color(0xFF3B342B),
  inverseSurface: Color(0xFFF1E8DC),
  onInverseSurface: Color(0xFF2B2118),
  inversePrimary: Color(0xFFC2603B),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
);

/// App-specific semantic colours that [ColorScheme] has no role for.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.positive,
    required this.onPositiveContainer,
    required this.positiveContainer,
  });

  /// Money someone is owed (positive balance).
  final Color positive;
  final Color positiveContainer;
  final Color onPositiveContainer;

  static const light = AppColors(
    positive: Color(0xFF3F7A4E),
    positiveContainer: Color(0xFFD8EAD9),
    onPositiveContainer: Color(0xFF17331E),
  );

  static const dark = AppColors(
    positive: Color(0xFF8DBF98),
    positiveContainer: Color(0xFF2F5A3B),
    onPositiveContainer: Color(0xFFD8EAD9),
  );

  static AppColors of(BuildContext context) => Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith({Color? positive, Color? positiveContainer, Color? onPositiveContainer}) {
    return AppColors(
      positive: positive ?? this.positive,
      positiveContainer: positiveContainer ?? this.positiveContainer,
      onPositiveContainer: onPositiveContainer ?? this.onPositiveContainer,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      positive: Color.lerp(positive, other.positive, t)!,
      positiveContainer: Color.lerp(positiveContainer, other.positiveContainer, t)!,
      onPositiveContainer: Color.lerp(onPositiveContainer, other.onPositiveContainer, t)!,
    );
  }
}

ThemeData buildLightTheme() => _build(_lightScheme, AppColors.light);

ThemeData buildDarkTheme() => _build(_darkScheme, AppColors.dark);

ThemeData _build(ColorScheme scheme, AppColors colors) {
  final base = ThemeData(
    brightness: scheme.brightness,
    colorScheme: scheme,
    fontFamily: _fontFamily,
  );

  // Titles are bold so hierarchy reads without relying on size alone.
  final textTheme = base.textTheme
      .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface)
      .copyWith(
        headlineSmall: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        titleSmall: base.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      );

  final cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
    side: BorderSide(color: scheme.outlineVariant),
  );
  const pill = StadiumBorder();
  const buttonPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 14);
  final buttonText = textTheme.labelLarge;

  return base.copyWith(
    textTheme: textTheme,
    scaffoldBackgroundColor: scheme.surface,
    extensions: [colors],
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
      shape: cardShape,
      clipBehavior: Clip.antiAlias,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: pill,
        padding: buttonPadding,
        minimumSize: const Size(64, 48),
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: pill,
        padding: buttonPadding,
        minimumSize: const Size(64, 48),
        side: BorderSide(color: scheme.outline),
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(shape: pill, textStyle: buttonText),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.error, width: 2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      elevation: 0,
      labelTextStyle: WidgetStatePropertyAll(
        textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      iconColor: scheme.onSurfaceVariant,
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        side: BorderSide(color: scheme.outline),
        selectedBackgroundColor: scheme.primaryContainer,
        selectedForegroundColor: scheme.onPrimaryContainer,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: textTheme.titleLarge,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
