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

  /// Standard inner padding for a panel/card-shaped surface (Apple range:
  /// generous breathing room between a container's edge and its content).
  static const double panelPadding = 24;
  /// Gap between sibling cards inside a panel (e.g. a `Stack`/`Wrap` of
  /// [ZCard]s).
  static const double cardGap = 16;
  /// Vertical gap between distinct sections within a panel.
  static const double sectionGap = 24;

  /// Width of the centered "home" block in an empty chat thread.
  static const double homeMaxWidth = 560;

  /// The chat composer grows up to this many lines, then scrolls inside.
  static const int composerMaxLines = 5;

  /// Left list in a two-pane dialog (Settings).
  static const double sideNavWidth = 196;
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
  /// Card/panel surfaces — top of the Apple "large radius" range (16-20).
  static const double card = 18;
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

  /// Pen-stroke draw-on (logo Z, correct-answer underline, empty-state
  /// illustrations). Use with [decel].
  static const Duration draw = Duration(milliseconds: 600);

  /// Spark pop (scale 0 -> 1). Use with [overshoot].
  static const Duration spark = Duration(milliseconds: 360);

  /// Spark hop-off for "course ready" (8px up + fade out).
  static const Duration sparkHop = Duration(milliseconds: 500);
}

/// Elevation scale. Apple only casts shadow in light mode — dark surfaces
/// read as "elevated" purely through the raised/raised2 fill contrast, so
/// [card] returns nothing under [Brightness.dark].
class ZShadow {
  ZShadow._();

  /// Gentle elevation for a card/panel surface, light mode only.
  static List<BoxShadow> card(Brightness brightness) {
    if (brightness == Brightness.dark) return const [];
    return const [
      BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 6)), // black @ 8%
      BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)), // black @ 4%
    ];
  }
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
    required this.accentText,
    required this.spark,
    required this.onSpark,
    required this.sparkText,
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
  /// Hibiscus for running text, links and active tabs. Equal to [accent] in
  /// light mode; a lighter pink in dark mode, where the deep fill is only
  /// ~3.8:1 as text. Fills keep [accent].
  final Color accentText;
  /// Amber "spark": delight only (streaks, cache hits, finished processing,
  /// the logo's pen-lift dot). Never a primary call to action.
  final Color spark;
  /// Text/icons placed on a [spark] fill.
  final Color onSpark;
  /// Amber for small text on [raised] (AA in both themes).
  final Color sparkText;
  final Color success;
  /// A darker/lighter variant of [success] for small text on [raised],
  /// tuned to reach the AA contrast minimum (~4.5:1). Use [success] for
  /// fills (badges, rings, bars); use this for running text.
  final Color successText;
  final Color warning;
  final Color danger;

  // Brand palette (docs/brand/BRAND.md s.3 / s.7). Ratios are WCAG 2.1.
  static const ZTokens light = ZTokens(
    surface: Color(0xFFF7F5F3), // Paper
    raised: Color(0xFFFFFFFF), // Card
    raised2: Color(0xFFEFEBE8), // Card 2; textSecondary on it 4.97:1
    hairline: Color(0x14000000), // black @ 8%
    text: Color(0xFF1F1A1C), // Ink; 17.17:1 on raised
    textSecondary: Color(0xFF6B6266), // 5.89:1 on raised
    textTertiary: Color(0xFF8C8387), // 3.68:1: large text / placeholders only
    accent: Color(0xFFC2255C), // Hibiscus 600; white on it 5.66:1
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0x1AC2255C), // accent @ 10%; accent text on it 4.83:1
    accentText: Color(0xFFC2255C), // 5.20:1 on surface
    spark: Color(0xFFFFB224), // Amber
    onSpark: Color(0xFF1F1A1C), // 9.52:1 on spark
    sparkText: Color(0xFF8A5300), // 6.33:1 on raised
    success: Color(0xFF1E8E5A), // Mint fill, 4.14:1 UI
    successText: Color(0xFF17774B), // 5.56:1 on raised
    warning: Color(0xFFB25000), // 5.20:1 on raised
    danger: Color(0xFFC4320A), // 5.52:1 on raised
  );

  static const ZTokens dark = ZTokens(
    surface: Color(0xFF0E0C0D),
    raised: Color(0xFF1C191A),
    raised2: Color(0xFF2A2628), // textSecondary on it 6.06:1
    hairline: Color(0x24FFFFFF), // white @ 14%
    text: Color(0xFFF6F2F3), // 15.72:1 on raised
    textSecondary: Color(0xFFABA3A6), // 7.08:1 on raised
    textTertiary: Color(0xFF7A7275), // 3.73:1: large text / placeholders only
    accent: Color(0xFFD6336C), // Hibiscus 500; white on it 4.62:1
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0x2ED6336C), // accent @ 18%; accentText on it 6.04:1
    accentText: Color(0xFFFF7AA2), // 7.11:1 on raised
    spark: Color(0xFFFFB224), // 9.68:1 on raised
    onSpark: Color(0xFF1F1A1C),
    sparkText: Color(0xFFFFB224), // 9.68:1 on raised
    success: Color(0xFF3DD68C), // 9.30:1 on raised
    successText: Color(0xFF3DD68C),
    warning: Color(0xFFFF9F0A), // 8.49:1 on raised
    danger: Color(0xFFFF6B4A), // 6.19:1 on raised
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
    Color? accentText,
    Color? spark,
    Color? onSpark,
    Color? sparkText,
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
      accentText: accentText ?? this.accentText,
      spark: spark ?? this.spark,
      onSpark: onSpark ?? this.onSpark,
      sparkText: sparkText ?? this.sparkText,
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
      accentText: Color.lerp(accentText, other.accentText, t)!,
      spark: Color.lerp(spark, other.spark, t)!,
      onSpark: Color.lerp(onSpark, other.onSpark, t)!,
      sparkText: Color.lerp(sparkText, other.sparkText, t)!,
      success: Color.lerp(success, other.success, t)!,
      successText: Color.lerp(successText, other.successText, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

/// Compact type scale with the Apple tracking rule: letter-spacing decreases
/// (goes negative) as size increases, line-height decreases as size grows.
/// Discrete steps, no interpolation. [display] and [title] render bold/
/// semibold (Apple large-title weight); body copy stays regular.
class ZType {
  ZType._();

  /// Landing and empty-thread hero line only. One per screen.
  static const double hero = 44;
  static const double display = 34;
  static const double title = 22;
  static const double headline = 17;
  static const double body = 15;
  static const double label = 13;
  static const double caption = 12;
  static const double micro = 11;

  /// Builds the [TextTheme] for [tokens], mapped onto Material slots:
  /// displayLarge=hero, displaySmall=display, titleLarge=title, titleMedium=headline,
  /// bodyLarge/bodyMedium=body, labelLarge=label, bodySmall=caption,
  /// labelSmall=micro.
  ///
  /// With [arabic], every slot gets the Arabic adjustment (see [arabic]):
  /// +0.15 line height, zero letter-spacing.
  static TextTheme textTheme(ZTokens tokens, {bool arabic = false}) {
    final base = TextTheme(
      displayLarge: _style(
        hero,
        height: 1.08,
        em: -0.012,
        color: tokens.text,
        weight: FontWeight.w600,
      ),
      displaySmall: _style(
        display,
        height: 1.10,
        em: -0.006,
        color: tokens.text,
        weight: FontWeight.w600,
      ),
      titleLarge: _style(
        title,
        height: 1.15,
        em: -0.002,
        color: tokens.text,
        weight: FontWeight.w600,
      ),
      titleMedium: _style(
        headline,
        height: 1.20,
        em: 0,
        color: tokens.text,
        weight: FontWeight.w600,
      ),
      bodyLarge: _style(body, height: 1.40, em: 0.002, color: tokens.text),
      bodyMedium: _style(body, height: 1.40, em: 0.002, color: tokens.textSecondary),
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
    if (!arabic) return base;
    TextStyle? a(TextStyle? s) => s == null ? null : ZType.arabic(s);
    return base.copyWith(
      displayLarge: a(base.displayLarge),
      displaySmall: a(base.displaySmall),
      titleLarge: a(base.titleLarge),
      titleMedium: a(base.titleMedium),
      bodyLarge: a(base.bodyLarge),
      bodyMedium: a(base.bodyMedium),
      labelLarge: a(base.labelLarge),
      bodySmall: a(base.bodySmall),
      labelSmall: a(base.labelSmall),
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
      fontFamily: fontFamily,
      fontSize: size,
      height: height,
      letterSpacing: size * em,
      color: color,
      fontWeight: weight,
      fontVariations: weightAxis(weight),
    );
  }

  /// Bundled brand family (assets/fonts/ReadexPro-Variable.ttf, one
  /// variable file covering Latin + Arabic, wght 160..700).
  static const String fontFamily = 'Readex Pro';

  /// The variable font's `wght` axis for [weight]. Readex Pro ships as a
  /// single variable file, so the engine needs the axis set explicitly to
  /// render true weights. [TextStyle.copyWith] with a new `fontWeight`
  /// should also pass `fontVariations: ZType.weightAxis(w)`, or use
  /// [ZType.withWeight].
  static List<FontVariation> weightAxis(FontWeight weight) =>
      [FontVariation('wght', weight.value.toDouble())];

  /// Returns [style] at [weight] with the matching variable-font axis.
  static TextStyle withWeight(TextStyle style, FontWeight weight) =>
      style.copyWith(fontWeight: weight, fontVariations: weightAxis(weight));

  /// Arabic adjustment: +0.15 line height (dots and descenders need room)
  /// and zero letter-spacing (tracking breaks the joins). Apply to any
  /// RTL / Arabic text: `ZType.arabic(context.type.bodyLarge!)`.
  static TextStyle arabic(TextStyle style) => style.copyWith(
        height: (style.height ?? 1.40) + 0.15,
        letterSpacing: 0,
      );
}

/// Builds the Material 3 [ThemeData] for [brightness] from [ZTokens].
///
/// Pass [arabic] when the UI locale is Arabic so the whole type scale drops
/// letter-spacing and gains +0.15 line height.
ThemeData buildTheme(Brightness brightness, {bool arabic = false}) {
  final tokens = brightness == Brightness.dark ? ZTokens.dark : ZTokens.light;
  final textTheme = ZType.textTheme(tokens, arabic: arabic);

  final colorScheme = ColorScheme.fromSeed(
    seedColor: tokens.accent,
    brightness: brightness,
  ).copyWith(
    primary: tokens.accent,
    onPrimary: tokens.onAccent,
    secondary: tokens.accentSoft,
    onSecondary: tokens.accentText,
    tertiary: tokens.spark,
    onTertiary: tokens.onSpark,
    error: tokens.danger,
    onError: tokens.onAccent,
    surface: tokens.raised,
    onSurface: tokens.text,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: ZType.fontFamily,
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
        foregroundColor: WidgetStatePropertyAll(tokens.accentText),
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
