# Zakerly brand

Zakerly (ذاكرلي) is the friend who already read your slides and will explain them as many times as you need.

Everything below serves that line. Files in this folder: `logo.svg`, `logo-dark.svg`, `lockup.svg`, `favicon.svg`, `brand-guide.html` (one page for the pitch deck).

---

## 1. Personality

| Trait | Do | Don't |
|---|---|---|
| **Senior student, not a system** | Talk like a friend one year ahead: "Let's go through slide 9 together." | Sound like a portal: "Your request has been processed." |
| **Honest about what it knows** | Say when something isn't in the course files and offer a way back. | Bluff, pad, or answer from the open internet. |
| **Calm under deadline** | Keep screens quiet. One accent, lots of room, short lines. | Use urgency, red, countdowns or guilt ("You haven't studied in 3 days"). |
| **Local and bilingual** | Write Egyptian Arabic that sounds spoken. Mix English course terms naturally ("الـ recursion"). | Translate English strings word for word into formal فصحى. |

---

## 2. Logo

### The idea

We keep the current mark and sharpen it. The Z is still one continuous pen stroke on a rounded tile, because the tutor draws its explanations. Two changes give it character:

1. **The bottom stroke runs longer than the top.** It reads as the pen finishing with an underline, the gesture you make under the thing that matters.
2. **A small amber "spark" sits where the pen lifts off, top right.** It is the moment something clicks. The spark becomes the brand's delight device (streaks, cache hits, finished processing).

### Geometry (64 unit grid)

All values are fractions of the tile side `s`, so the mark scales continuously from favicon to splash.

| Element | SVG (64 grid) | Fraction of `s` |
|---|---|---|
| Tile | `rect 0,0,64,64 rx=18` | corner radius `0.28125s` (current code uses `0.28s`, keep that) |
| Pen stroke width | `9` | `0.140625s` |
| Stroke caps and joins | round | round |
| Z point 1 (top left) | `17, 23` | `0.265625s, 0.359375s` |
| Z point 2 (top right) | `37, 23` | `0.578125s, 0.359375s` |
| Z point 3 (bottom left) | `19, 44` | `0.296875s, 0.6875s` |
| Z point 4 (bottom right) | `45, 44` | `0.703125s, 0.6875s` |
| Spark centre | `48, 16` | `0.75s, 0.25s` |
| Spark radius | `4` | `0.0625s` |

SVG path: `M17 23H37L19 44H45`. Total path length is 73.66 units (20 + 27.66 + 26), useful for `stroke-dasharray` draw-on.

Colors: tile `accent` (Hibiscus), stroke `onAccent` (white), spark `spark` (Amber). The tile carries its own background, so the mark never needs a plate.

### CustomPainter recipe

Replace the body of `_ZMarkPainter.paint` with this (logic only, no new tokens beyond `spark`):

```dart
final s = side;
Offset p(double x, double y) => rect.topLeft + Offset(x * s, y * s);
canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(s * 0.28)), Paint()..color = fill);
final z = Path()
  ..moveTo(p(0.265625, 0.359375).dx, p(0.265625, 0.359375).dy)
  ..lineTo(p(0.578125, 0.359375).dx, p(0.578125, 0.359375).dy)
  ..lineTo(p(0.296875, 0.6875).dx, p(0.296875, 0.6875).dy)
  ..lineTo(p(0.703125, 0.6875).dx, p(0.703125, 0.6875).dy);
// For the draw-on animation, extract z.computeMetrics() and draw extractPath(0, len * t).
canvas.drawPath(z, Paint()
  ..color = stroke
  ..style = PaintingStyle.stroke
  ..strokeWidth = s * 0.140625
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round);
canvas.drawCircle(p(0.75, 0.25), s * 0.0625 * sparkScale, Paint()..color = spark);
```

### Wordmark and lockup

- Latin: "Zakerly", Readex Pro SemiBold (600), tracking `-0.01em`, sentence case. Never all caps.
- Arabic: "ذاكرلي", Readex Pro Medium (500), no tracking (never letter-space Arabic), `textSecondary` color.
- Stacked lockup (default, `lockup.svg`): mark height `H`; gap `0.25H`; Latin at `0.47H` font size, Arabic at `0.30H` below it. Both left-aligned to the same x.
- Inline lockup (nav bars, 32px mark): mark, `12px` gap, "Zakerly" at 17px 600. Arabic can drop out at this size or sit after a thin `·` separator.
- In an RTL UI, mirror the lockup: mark on the right, Arabic on top, Latin below. The mark itself never mirrors.

### Clear space and minimum size

- Clear space on every side = `0.25H` (the same as the gap between mark and wordmark). Nothing enters it.
- Minimum mark: **20px** on screen with the standard file. Between 16 and 20px use `favicon.svg`, which thickens the stroke to 10 and enlarges the spark to r5 so both survive.
- Minimum lockup: mark at 28px.

### Don'ts

- Don't recolor the tile outside the palette, add gradients, glows or drop shadows.
- Don't square off the stroke ends, change the stroke width, or italicise the Z.
- Don't move the spark, recolor it to white, or use it as a separate logo.
- Don't outline the tile or place the mark on a busy photo without a plain surface behind it.
- Don't set the wordmark in any other typeface.

---

## 3. Color

**Primary: Hibiscus.** A warm berry red, named for karkadeh (كركديه), the hibiscus drink every Egyptian knows. It is warm without being childish, reads as confident next to the endless blue of university and fintech apps, and pairs with amber the way the drink pairs with the glass it sits in. Supporting: **Amber** (the spark, streaks, delight) and **Mint** (success, correct answers).

All ratios below are WCAG 2.1, computed. AA needs 4.5:1 for body text, 3:1 for large text (18.66px bold, 24px regular) and UI boundaries.

### Light

| Role | Hex | Pairing | Ratio | Passes |
|---|---|---|---|---|
| Surface | `#F7F5F3` | text `#1F1A1C` | 15.79 | AAA |
| Raised | `#FFFFFF` | text `#1F1A1C` | 17.17 | AAA |
| Raised 2 | `#EFEBE8` | textSecondary `#6B6266` | 4.97 | AA |
| Text | `#1F1A1C` | | | |
| Text secondary | `#6B6266` | on raised | 5.89 | AA |
| Text tertiary | `#8C8387` | on raised | 3.68 | large text and placeholders only |
| Hairline | `#000000` at 8% | | | |
| **Accent (Hibiscus 600)** | `#C2255C` | white text on accent | 5.66 | AA |
| | | accent as text on surface | 5.20 | AA |
| Accent soft | `#C2255C` at 10% (`#F9E9EF` on white) | accent text on it | 4.83 | AA |
| **Spark (Amber)** | `#FFB224` | text `#1F1A1C` on spark | 9.52 | AAA |
| | | on Hibiscus tile (logo) | 3.14 (2.56 on the dark tile) | logos are exempt from 1.4.11; the white Z carries legibility |
| Spark text | `#8A5300` | on raised | 6.33 | AA |
| Success fill (Mint) | `#1E8E5A` | on raised as a UI fill | 4.14 | 3:1 UI |
| Success text | `#17774B` | on raised | 5.56 | AA |
| Warning | `#B25000` | on raised | 5.20 | AA |
| Danger | `#C4320A` | on raised | 5.52 | AA |

Danger sits orange of Hibiscus on purpose, so an error never looks like a brand button. Errors always carry an icon and a sentence, never color alone.

### Dark

| Role | Hex | Pairing | Ratio | Passes |
|---|---|---|---|---|
| Surface | `#0E0C0D` | text `#F6F2F3` | 17.56 | AAA |
| Raised | `#1C191A` | text `#F6F2F3` | 15.72 | AAA |
| Raised 2 | `#2A2628` | textSecondary `#ABA3A6` | 6.06 | AA |
| Text | `#F6F2F3` | | | |
| Text secondary | `#ABA3A6` | on raised | 7.08 | AAA |
| Text tertiary | `#7A7275` | on raised | 3.73 | large text and placeholders only |
| Hairline | `#FFFFFF` at 14% | | | |
| **Accent (Hibiscus 500)** | `#D6336C` | white text on accent | 4.62 | AA |
| | | accent fill on surface | 4.22 | 3:1 UI |
| Accent text (links, active tab) | `#FF7AA2` | on raised | 7.11 | AAA |
| Accent soft | `#D6336C` at 18% (`#3D1E29` on raised) | accent text on it | 6.04 | AA |
| **Spark (Amber)** | `#FFB224` | on raised | 9.68 | AAA |
| Spark text | `#FFB224` | on raised | 9.68 | AAA |
| Success (Mint) | `#3DD68C` | on raised | 9.30 | AAA |
| Warning | `#FF9F0A` | on raised | 8.49 | AAA |
| Danger | `#FF6B4A` | on raised | 6.19 | AA |

Why the dark accent splits in two: a fill that carries white text has to stay fairly deep (`#D6336C`), but that same color as text on near-black is only 3.78:1. So text uses the lighter `#FF7AA2`.

### Usage ratio

Roughly 85% neutrals, 10% Hibiscus, under 5% Amber and Mint combined. One Hibiscus call to action per screen. Amber only appears when something good just happened.

---

## 4. Typography

**Readex Pro** (Google Fonts, variable weight 160 to 700, OFL).

Why this one:

- One family draws both scripts, so Latin and Arabic share stroke weight, x-height feel and rhythm. No mismatched pairing to tune.
- It is the Arabic extension of Lexend, a family built from reading-proficiency research. That is the right story for a study app, and it shows: open counters, generous spacing, calm at body size.
- Its round, slightly soft geometry matches the rounded pen stroke of the mark and feels young without looking like a toy. Rubik was the runner-up; it is friendlier but gets heavy at display size and its Arabic is less refined.

Flutter: `google_fonts` (`GoogleFonts.readexProTextTheme`) or bundle the variable TTF under `assets/fonts` and set `fontFamily: 'Readex Pro'` in `buildTheme`. Web: `https://fonts.googleapis.com/css2?family=Readex+Pro:wght@300..700&display=swap`.

### Scale

Keeps the existing `ZType` sizes and Apple tracking rule. Arabic gets +0.15 line height and zero tracking at every step, because Arabic ascenders, descenders and dots need the room and letter-spacing breaks joins.

| Token | Size | Weight | Line height (Latin / Arabic) | Tracking (Latin only) | Use |
|---|---|---|---|---|---|
| `display` | 34 | 600 | 1.10 / 1.25 | -0.006em | Screen hero, course name |
| `title` | 22 | 600 | 1.15 / 1.30 | -0.002em | Panel titles |
| `headline` | 17 | 600 | 1.20 / 1.35 | 0 | Card titles, lockup |
| `body` | 15 | 400 | 1.40 / 1.55 | +0.002em | Chat, explanations |
| `label` | 13 | 500 | 1.35 / 1.50 | +0.004em | Buttons, chips |
| `caption` | 12 | 400 | 1.40 / 1.55 | +0.006em | Meta, timestamps |
| `micro` | 11 | 500 | 1.45 / 1.60 | +0.008em | Badges |

Body line height moves from 1.30 to 1.40: chat answers are long reading, and 1.30 is tight for them.

Numerals: Western digits (1, 2, 3) in both languages, matching Canvas and lecture slides.

---

## 5. Shape, icons, motion

### Shape

Everything echoes the tile: continuous rounded rectangles. Keep `ZRadius` as is (sm 8, md 12, lg 16, card 18, xl 22, pill). Chat bubbles use `lg` with the corner nearest the speaker at `sm`. No sharp corners anywhere, no borders heavier than a hairline.

### Icons

Line icons at 1.75px stroke on a 24 grid, round caps and joins, so they share the mark's pen. Material Symbols Rounded at weight 400, grade 0, fill 0 matches closely. Filled variant only for the selected tab. Icons are `textSecondary` by default, accent only when active.

### Motion personality: a pen, not a slot machine

Motion should feel like someone writing: it starts decisively, settles gently, and finishes before you notice. Rules, straight from the Apple teardown and already in `ZMotion`:

- Animate opacity and transform only. Draw-on strokes animate path length, which is the pen equivalent.
- Arrivals use `ZMotion.overshoot` (`cubic-bezier(0.3, 2, 0.5, 1)`) or decel; exits use `easeInQuad` and run about 3x faster (`enter` 500ms, `exit` 150ms). Nobody waits for something to leave.
- On entry, movement finishes before the fade (`staggerTranslate` 700ms, `staggerOpacity` 900ms). The element lands, then resolves.
- Travel scales with size: 8px for list items, 30px for sections, 4px for inline hints.
- Drive compound effects from one progress value (the animation window below uses a single `t` for inset and radius).
- Reduced motion: every moment below has a static end state and is skipped entirely, not shortened.

Suggested additions to `ZMotion`: `draw = 600ms` (stroke draw-on, decel) and `spark = 360ms` (spark pop, overshoot).

### Delight moments to build

1. **The mark writes itself.** On splash and login, the Z stroke draws from point 1 to 4 over 600ms (decel), then the spark pops from scale 0 to 1 with overshoot at 520ms. Once per session. Reuses the `ZLogo` controller.
2. **Course ready.** When a course finishes processing, its progress ring closes, the ring turns Mint, and the Amber spark hops off the ring (8px up, fade out, 500ms). Copy: "Ready. Ask me anything from Data Structures." No confetti.
3. **The animation window opens like a page.** The explanation canvas grows from the message bubble using one progress value that drives both inset and corner radius (22 to 18), then the diagram draws on stroke by stroke. When it came from the class cache, a small chip fades in: "Already drawn for your class" with the spark icon, turning a cost saving into a nice surprise.
4. **Correct answer underline.** In Quiz me, a correct option gets a Mint underline that draws left to right (or right to left in Arabic) under the text in 400ms, the same gesture as the Z's bottom stroke. Wrong answers get no shake, just a calm hint.
5. **Study streak spark.** Each day you study, a small Amber spark in the header fills in with a 360ms pop. Tap it for "4 days in a row." Missing a day resets quietly, with no guilt message.
6. **Empty states drawn with the same pen.** One tiny single-stroke illustration per empty state (an open notebook for no courses, a speech bubble for a new chat), 1.75px round-cap lines in `textTertiary`, plus one Amber dot. They draw on once when the screen appears.

---

## 6. Voice

### Rules

1. **Talk like a senior student.** Use "you" and "I". "I read your slides" beats "Documents have been indexed."
2. **Say what happened, then what to do next.** Every error and empty state ends with an action.
3. **Arabic is written, not translated.** Egyptian spoken register, English course terms kept in English, Western digits. If a string sounds like a government form, rewrite it.
4. **Never blame the student.** It's "Canvas isn't answering", not "You entered an invalid token."
5. **Be honest about the source.** If it isn't in the course files, say so plainly and suggest where to look.
6. **Keep it short.** One idea per line, at most one exclamation mark per screen, no emoji in system text.

### Before and after

| Where | Before | After (EN) | After (AR) |
|---|---|---|---|
| Sign in | Authenticate with Canvas access token | Connect your Canvas | وصّل حساب Canvas بتاعك |
| Processing | Processing course files... | Reading your slides. Give me a minute. | بقرا السلايدز بتاعتك. دقيقة واحدة. |
| Course ready | Indexing complete. | Ready. Ask me anything from Data Structures. | خلصت. اسألني أي حاجة في Data Structures. |
| No courses | No courses found. | No courses yet. Pull them from Canvas and we'll start. | مفيش مواد لسه. هاتها من Canvas ونبدأ. |
| Out of scope | The answer is not available in the provided context. | I couldn't find this in your course files. Want to try something from Week 4? | ملقتش ده في ملفات المادة. تحب نشوف حاجة من Week 4؟ |
| Quiz, wrong | Incorrect answer. | Close. Look at slide 12 again. | قربت. بص على سلايد 12 تاني. |
| Cache hit | Loaded from cache. | Already drawn for your class. | اترسمت قبل كده لدفعتك، جاهزة على طول. |
| Budget | Token quota: 78% consumed. | You've used most of this week's budget. It resets Sunday. | استهلكت أغلب رصيد الأسبوع. بيتجدد يوم الحد. |
| Network error | Error: request failed (500). | Canvas isn't answering right now. Try again in a bit. | Canvas مش بيرد دلوقتي. جرّب كمان شوية. |
| Chat placeholder | Enter your question | Ask about this course | اسأل في المادة دي |

Mode names stay short and parallel: **Explain / Socratic / Quiz me**, in Arabic **اشرحلي / ناقشني / امتحنّي**.

---

## 7. Tokens for Flutter

Apply in `lib/ui/theme.dart`. Existing names first; new tokens are marked **new** and need adding to `ZTokens` (constructor, `copyWith`, `lerp`).

| Brand name | Token | Light | Dark |
|---|---|---|---|
| Paper | `surface` | `0xFFF7F5F3` | `0xFF0E0C0D` |
| Card | `raised` | `0xFFFFFFFF` | `0xFF1C191A` |
| Card 2 | `raised2` | `0xFFEFEBE8` | `0xFF2A2628` |
| Hairline | `hairline` | `0x14000000` | `0x24FFFFFF` |
| Ink | `text` | `0xFF1F1A1C` | `0xFFF6F2F3` |
| Ink 2 | `textSecondary` | `0xFF6B6266` | `0xFFABA3A6` |
| Ink 3 | `textTertiary` | `0xFF8C8387` | `0xFF7A7275` |
| Hibiscus | `accent` | `0xFFC2255C` | `0xFFD6336C` |
| On Hibiscus | `onAccent` | `0xFFFFFFFF` | `0xFFFFFFFF` |
| Hibiscus soft | `accentSoft` | `0x1AC2255C` | `0x2ED6336C` |
| Hibiscus text **new** | `accentText` | `0xFFC2255C` | `0xFFFF7AA2` |
| Amber **new** | `spark` | `0xFFFFB224` | `0xFFFFB224` |
| On Amber **new** | `onSpark` | `0xFF1F1A1C` | `0xFF1F1A1C` |
| Amber text **new** | `sparkText` | `0xFF8A5300` | `0xFFFFB224` |
| Mint | `success` | `0xFF1E8E5A` | `0xFF3DD68C` |
| Mint text | `successText` | `0xFF17774B` | `0xFF3DD68C` |
| Warning | `warning` | `0xFFB25000` | `0xFFFF9F0A` |
| Danger | `danger` | `0xFFC4320A` | `0xFFFF6B4A` |

Wiring notes:

- `textButtonTheme` foreground and any accent-colored text should read `accentText`, not `accent`. Fills keep `accent`.
- `ColorScheme.fromSeed(seedColor: accent)` stays; the `copyWith` overrides already pin the important slots. Add `tertiary: spark, onTertiary: onSpark`.
- Typography: add `fontFamily: 'Readex Pro'` to `ThemeData`, change `bodyLarge`/`bodyMedium` height from 1.30 to 1.40, and set `displaySmall` and `titleLarge` weight to `w600`. For RTL text apply `height + 0.15` and `letterSpacing: 0` (a `ZType.arabic(TextStyle)` helper keeps this in one place).
- `_ZMarkPainter` takes a third color, `spark`, and the new geometry from section 2.
- `web/favicon.svg` becomes `docs/brand/favicon.svg`.
- `ZMotion`: add `draw = Duration(milliseconds: 600)` and `spark = Duration(milliseconds: 360)`.
