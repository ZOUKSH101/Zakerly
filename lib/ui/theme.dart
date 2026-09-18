// Zakerly design tokens: colors, spacing, radius, motion and type scale.
//
// Owned by the design-system agent. Everyone else reads tokens via
// `context.z` / `context.type` — no raw hex, no ad-hoc font sizes.
import 'package:flutter/material.dart';

/// Spacing scale: 4 / 8 / 12 / 16 / 20 / 24 / 32.
class ZSpace {
  ZSpace._();

  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
}

/// Layout constants shared across features.
class ZLayout {
  ZLayout._();

  static const double formMaxWidth = 400;
  static const double segmentedWidth = 260;
  static const double bubbleMaxWidth = 640;
  static const double bubbleMaxFraction = 0.72;
  /// Below this width, headers stack instead of sitting in a row.
  static const double compactBreakpoint = 520;
  static const double pillRingSize = 18;
  static const double pillRingStroke = 2.5;
}

/// Icon sizes used across primitives and features.
class ZIcon {
  ZIcon._();

  static const double sm = 14;
  static const double md = 18;
  static const double lg = 20;
}

/// Corner radius scale.
class ZRadius {
  ZRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 22;
  static const double pill = 999;
}

/// Motion durations, curves and stagger constants (Apple teardown, ss.5-8).
class ZMotion {
  ZMotion._();

  // Durations.
  static const Duration enter = Duration(milliseconds: 500);
  static const Duration medium = Duration(milliseconds: 240);
  static const Duration exit = Duration(milliseconds: 150);

  // Curves.
  static const Curve decel = Cubic(0, 0, 0.5, 1);
  static const Curve standard = Cubic(0.4, 0, 0.6, 1);
  /// Arrivals only.
  static const Curve overshoot = Cubic(0.3, 2, 0.5, 1);
  static const Curve exitCurve = Curves.easeInQuad;

  // Stagger (FadeSlideIn / StaggeredFadeIn).
  static const Duration staggerTranslate = Duration(milliseconds: 700);
  static const Duration staggerOpacity = Duration(milliseconds: 900);
  static const double staggerSectionTravel = 30;
  static const double staggerItemTravel = 8;
  static const int staggerStepMs = 90;
  static const int staggerMaxIndex = 8;

  /// One bounce cycle of [ZTypingDots].
  static const Duration typingCycle = Duration(milliseconds: 1200);
}

/// Palette + semantic colors, theme-aware via [ThemeExtension].
class ZTokens extends ThemeExtension<ZTokens> {
  const ZTokens({
    required this.surface,
    required this.raised,
    required this.raised2,
    required this.hairline,
    required this.text,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.success,
    required this.successText,
    required this.warning,
    required this.danger,
  });

  final Color surface;
  final Color raised;
  final Color raised2;
  final Color hairline;
  final Color text;
  final Color textSecondary;
  final Color textTertiary;
  final Color accent;
  final Color onAccent;
  final Color accentSoft;
  final Color success;
  /// A darker/lighter variant of [success] for small text on [raised],
  /// tuned to reach the AA contrast minimum (~4.5:1). Use [success] for
  /// fills (badges, rings, bars); use this for running text.
  final Color successText;
  final Color warning;
  final Color danger;

  static const ZTokens light = ZTokens(
    surface: Color(0xFFF5F5F7),
    raised: Color(0xFFFFFFFF),
    raised2: Color(0xFFEDEDF0),
    hairline: Color(0x14000000), // black @ 8%
    text: Color(0xFF1D1D1F),
    textSecondary: Color(0xFF6E6E73),
    textTertiary: Color(0xFF8E8E93),
    accent: Color(0xFF3F5EFB),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0x1A3F5EFB), // accent @ 10%
    success: Color(0xFF248A3D),
    successText: Color(0xFF1F7A35), // ~5.4:1 on raised (white)
    warning: Color(0xFFB25000),
    danger: Color(0xFFD70015),
  );

  static const ZTokens dark = ZTokens(
    surface: Color(0xFF000000),
    raised: Color(0xFF1C1C1E),
    raised2: Color(0xFF2C2C2E),
    hairline: Color(0x24FFFFFF), // white @ 14%
    text: Color(0xFFF5F5F7),
    textSecondary: Color(0xFFA1A1A6),
    textTertiary: Color(0xFF6E6E73),
    // #5E7BFF was only ~3.7:1 with white onAccent text; #4C63F5 is ~4.76:1
    // (still a bright indigo-blue).
    accent: Color(0xFF4C63F5),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0x294C63F5), // accent @ 16%
    success: Color(0xFF30D158),
    successText: Color(0xFF30D158), // ~8.4:1 on raised (#1C1C1E), stays as-is
    warning: Color(0xFFFF9F0A),
    danger: Color(0xFFFF453A),
  );

  @override
  ZTokens copyWith({
    Color? surface,
    Color? raised,
    Color? raised2,
    Color? hairline,
    Color? text,
    Color? textSecondary,
    Color? textTertiary,
    Color? accent,
    Color? onAccent,
    Color? accentSoft,
    Color? success,
    Color? successText,
    Color? warning,
    Color? danger,
  }) {
    return ZTokens(
      surface: surface ?? this.surface,
      raised: raised ?? this.raised,
      raised2: raised2 ?? this.raised2,
      hairline: hairline ?? this.hairline,
      text: text ?? this.text,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentSoft: accentSoft ?? this.accentSoft,
      success: success ?? this.success,
      successText: successText ?? this.successText,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
    );
  }

  @override
  ZTokens lerp(ThemeExtension<ZTokens>? other, double t) {
    if (other is! ZTokens) return this;
    return ZTokens(
      surface: Color.lerp(surface, other.surface, t)!,
      raised: Color.lerp(raised, other.raised, t)!,
      raised2: Color.lerp(raised2, other.raised2, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      text: Color.lerp(text, other.text, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      success: Color.lerp(success, other.success, t)!,
      successText: Color.lerp(successText, other.successText, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

/// Compact type scale with the Apple tracking rule: letter-spacing decreases
/// (goes negative) as size increases, line-height decreases as size grows.
/// Discrete steps, no interpolation.
class ZType {
  ZType._();

  static const double display = 34;
  static const double title = 22;
  static const double headline = 17;
  static const double body = 15;
  static const double label = 13;
  static const double caption = 12;
  static const double micro = 11;

  /// Builds the [TextTheme] for [tokens], mapped onto Material slots:
  /// displaySmall=display, titleLarge=title, titleMedium=headline,
  /// bodyLarge/bodyMedium=body, labelLarge=label, bodySmall=caption,
  /// labelSmall=micro.
  static TextTheme textTheme(ZTokens tokens) {
    return TextTheme(
      displaySmall: _style(display, height: 1.10, em: -0.006, color: tokens.text),
      titleLarge: _style(title, height: 1.15, em: -0.002, color: tokens.text),
      titleMedium: _style(
        headline,
        height: 1.20,
        em: 0,
        color: tokens.text,
        weight: FontWeight.w600,
      ),
      bodyLarge: _style(body, height: 1.30, em: 0.002, color: tokens.text),
      bodyMedium: _style(body, height: 1.30, em: 0.002, color: tokens.textSecondary),
      labelLarge: _style(
        label,
        height: 1.35,
        em: 0.004,
        color: tokens.text,
        weight: FontWeight.w500,
      ),
      bodySmall: _style(caption, height: 1.40, em: 0.006, color: tokens.textSecondary),
      labelSmall: _style(micro, height: 1.45, em: 0.008, color: tokens.textTertiary),
    );
  }

  static TextStyle _style(
    double size, {
    required double height,
    required double em,
    required Color color,
    FontWeight weight = FontWeight.w400,
  }) {
    return TextStyle(
      fontSize: size,
      height: height,
      letterSpacing: size * em,
      color: color,
      fontWeight: weight,
    );
  }
}

/// Builds the Material 3 [ThemeData] for [brightness] from [ZTokens].
ThemeData buildTheme(Brightness brightness) {
  final tokens = brightness == Brightness.dark ? ZTokens.dark : ZTokens.light;
  final textTheme = ZType.textTheme(tokens);

  final colorScheme = ColorScheme.fromSeed(
    seedColor: tokens.accent,
    brightness: brightness,
  ).copyWith(
    primary: tokens.accent,
    onPrimary: tokens.onAccent,
    secondary: tokens.accentSoft,
    onSecondary: tokens.accent,
    error: tokens.danger,
    onError: tokens.onAccent,
    surface: tokens.raised,
    onSurface: tokens.text,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: tokens.surface,
    visualDensity: VisualDensity.compact,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: tokens.hairline,
    dividerColor: tokens.hairline,
    textTheme: textTheme,
    extensions: [tokens],
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: tokens.raised,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: ZSpace.s16,
        vertical: ZSpace.s12,
      ),
      hintStyle: textTheme.bodyLarge?.copyWith(color: tokens.textTertiary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ZRadius.md),
        borderSide: BorderSide(color: tokens.hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ZRadius.md),
        borderSide: BorderSide(color: tokens.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ZRadius.md),
        borderSide: BorderSide(color: tokens.accent, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(tokens.accent),
        foregroundColor: WidgetStatePropertyAll(tokens.onAccent),
        splashFactory: NoSplash.splashFactory,
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(ZRadius.md)),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(tokens.accent),
        splashFactory: NoSplash.splashFactory,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected) ? tokens.accent : tokens.raised2;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected) ? Colors.transparent : tokens.hairline;
      }),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: tokens.raised,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ZRadius.xl)),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: tokens.text,
        borderRadius: BorderRadius.circular(ZRadius.sm),
      ),
      textStyle: textTheme.bodySmall?.copyWith(color: tokens.surface),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: tokens.accent,
      inactiveTrackColor: tokens.raised2,
      thumbColor: tokens.accent,
      overlayColor: tokens.accentSoft,
      valueIndicatorColor: tokens.text,
      valueIndicatorTextStyle: textTheme.bodySmall?.copyWith(color: tokens.raised),
    ),
  );
}

/// Convenience access to design tokens and text styles from a [BuildContext].
extension ZContext on BuildContext {
  ZTokens get z => Theme.of(this).extension<ZTokens>()!;
  TextTheme get type => Theme.of(this).textTheme;
}
