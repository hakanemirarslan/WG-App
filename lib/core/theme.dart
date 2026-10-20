import 'package:flutter/material.dart';

/// Central look of the app (modern, vibrant, premium).
/// Screens read colours from `Theme.of(context).colorScheme` and [AppColors];
/// no hard-coded colours elsewhere.
const _fontFamily = 'Nunito';

// ── Light scheme ──────────────────────────────────────────────────────────────
// Deep violet-indigo primary with warm amber accent and soft teal tertiary.
const _lightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF5B4CF5), // vibrant indigo-violet
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFE8E4FF),
  onPrimaryContainer: Color(0xFF1A0E6E),
  secondary: Color(0xFFF0A500), // warm amber-gold
  onSecondary: Color(0xFF1A1000),
  secondaryContainer: Color(0xFFFFF0C2),
  onSecondaryContainer: Color(0xFF3A2800),
  tertiary: Color(0xFF00A896), // teal-mint
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFBDF5EE),
  onTertiaryContainer: Color(0xFF003330),
  error: Color(0xFFE53935),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFFDAD6),
  onErrorContainer: Color(0xFF410002),
  surface: Color(0xFFF8F7FF),
  onSurface: Color(0xFF1C1B2E),
  onSurfaceVariant: Color(0xFF5B5977),
  outline: Color(0xFF9896B0),
  outlineVariant: Color(0xFFDFDDF4),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFF3F1FF),
  surfaceContainer: Color(0xFFEFEDFC),
  surfaceContainerHigh: Color(0xFFE9E7F9),
  surfaceContainerHighest: Color(0xFFE3E1F5),
  inverseSurface: Color(0xFF302F45),
  onInverseSurface: Color(0xFFF8F7FF),
  inversePrimary: Color(0xFFBDB3FF),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
);

// ── Dark scheme ───────────────────────────────────────────────────────────────
const _darkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFBDB3FF), // lighter violet for dark
  onPrimary: Color(0xFF2A1F8E),
  primaryContainer: Color(0xFF4035CC),
  onPrimaryContainer: Color(0xFFE8E4FF),
  secondary: Color(0xFFFFD54F), // warm golden yellow
  onSecondary: Color(0xFF3A2800),
  secondaryContainer: Color(0xFF5A4000),
  onSecondaryContainer: Color(0xFFFFF0C2),
  tertiary: Color(0xFF4DDCC8), // bright teal
  onTertiary: Color(0xFF00201D),
  tertiaryContainer: Color(0xFF00524A),
  onTertiaryContainer: Color(0xFFBDF5EE),
  error: Color(0xFFFF8A80),
  onError: Color(0xFF690005),
  errorContainer: Color(0xFF93000A),
  onErrorContainer: Color(0xFFFFDAD6),
  surface: Color(0xFF111028), // deep indigo-black
  onSurface: Color(0xFFE8E6FF),
  onSurfaceVariant: Color(0xFFCBC8E8),
  outline: Color(0xFF928FA8),
  outlineVariant: Color(0xFF3A3858),
  surfaceContainerLowest: Color(0xFF0B0A1E),
  surfaceContainerLow: Color(0xFF171630),
  surfaceContainer: Color(0xFF1C1B36),
  surfaceContainerHigh: Color(0xFF23223F),
  surfaceContainerHighest: Color(0xFF2B2A4A),
  inverseSurface: Color(0xFFE8E6FF),
  onInverseSurface: Color(0xFF1C1B2E),
  inversePrimary: Color(0xFF5B4CF5),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
);

// ── App-specific semantic colours ─────────────────────────────────────────────
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({required this.onPositiveContainer, required this.positiveContainer});

  /// Background for money someone is owed (positive balance) and the text on it.
  final Color positiveContainer;
  final Color onPositiveContainer;

  static const light = AppColors(
    positiveContainer: Color(0xFFBDF5EE),
    onPositiveContainer: Color(0xFF003330),
  );

  static const dark = AppColors(
    positiveContainer: Color(0xFF00524A),
    onPositiveContainer: Color(0xFFBDF5EE),
  );

  static AppColors of(BuildContext context) => Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith({Color? positiveContainer, Color? onPositiveContainer}) {
    return AppColors(
      positiveContainer: positiveContainer ?? this.positiveContainer,
      onPositiveContainer: onPositiveContainer ?? this.onPositiveContainer,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
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
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        titleSmall: base.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      );

  final cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
    side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
  );
  const pill = StadiumBorder();
  const buttonPadding = EdgeInsets.symmetric(horizontal: 28, vertical: 14);
  final buttonText = textTheme.labelLarge;

  return base.copyWith(
    textTheme: textTheme,
    // Transparent so the shapes from `AppBackground` show through every screen.
    scaffoldBackgroundColor: Colors.transparent,
    extensions: [colors],
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
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
        minimumSize: const Size(64, 50),
        textStyle: buttonText,
        elevation: 0,
      ).copyWith(overlayColor: WidgetStateProperty.all(scheme.onPrimary.withValues(alpha: 0.15))),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: pill,
        padding: buttonPadding,
        minimumSize: const Size(64, 50),
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
      elevation: 4,
      highlightElevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.error, width: 2),
      ),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      floatingLabelStyle: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerLowest.withValues(alpha: 0.92),
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      elevation: 0,
      labelTextStyle: WidgetStatePropertyAll(
        textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      iconColor: scheme.primary,
      minVerticalPadding: 12,
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return scheme.primary;
        return null;
      }),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titleTextStyle: textTheme.titleLarge,
      elevation: 8,
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
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: TextStyle(color: scheme.onInverseSurface, fontFamily: _fontFamily),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    chipTheme: ChipThemeData(
      shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant)),
      backgroundColor: scheme.surfaceContainerLow,
      labelStyle: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}
