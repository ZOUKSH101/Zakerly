import 'budget.dart';
import 'cache.dart';
import 'models.dart';
import 'preferences.dart';
import 'prompts.dart';
import 'providers.dart';
import 'retrieval.dart';
import 'scheduler.dart';
import 'services.dart';
import 'util.dart';

class AnimationResult {
  const AnimationResult({
    required this.concept,
    required this.html,
    required this.tokens,
    required this.fromCache,
  });
  final String concept, html;
  final int tokens;
  final bool fromCache;
}

class AnimationLimitReached implements Exception {
  const AnimationLimitReached(this.message, {required this.perDay});

  /// English copy for logs. The UI words it from [perDay] (`S.limitBody`).
  final String message;
  final int perDay;
  @override
  String toString() => message;
}

/// Which app theme the animation document is drawn for. The document takes
/// its colours from this, not from the OS `prefers-color-scheme`, so it
/// matches the app when the two differ.
enum AnimationTheme { light, dark }

/// The frame palette for each [AnimationTheme], mirroring the app's design
/// tokens (lib/ui/theme.dart ZTokens: raised, text, textSecondary, raised2,
/// accent, accentText). Shared by the real prompt and the mock documents.
class AnimationPalette {
  const AnimationPalette._({
    required this.bg,
    required this.fg,
    required this.muted,
    required this.card,
    required this.border,
    required this.accent,
    required this.accentText,
    required this.accentWeak,
  });

  final String bg, fg, muted, card, border, accent, accentText, accentWeak;

  static const light = AnimationPalette._(
    bg: '#FFFFFF',
    fg: '#1F1A1C',
    muted: '#6B6266',
    card: '#EFEBE8',
    border: '#D9D2D5',
    accent: '#C2255C',
    accentText: '#C2255C',
    accentWeak: '#FBE7EE',
  );

  static const dark = AnimationPalette._(
    bg: '#1C191A',
    fg: '#F6F2F3',
    muted: '#ABA3A6',
    card: '#2A2628',
    border: '#3D383A',
    accent: '#D6336C',
    accentText: '#FF7AA2',
    accentWeak: '#3A1522',
  );

  static AnimationPalette of(AnimationTheme theme) => theme == AnimationTheme.dark ? dark : light;

  /// The palette as CSS custom properties on `:root`.
  String get css => ':root{--bg:$bg;--fg:$fg;--muted:$muted;--card:$card;--border:$border;'
      '--accent:$accent;--accent-text:$accentText;--accent-weak:$accentWeak;}';

  /// One line for the model prompt.
  String get describe => 'background $bg, text $fg, muted text $muted, card $card, '
      'border $border, accent fill $accent (white text on it), accent text $accentText, '
      'soft accent tint $accentWeak';
}

/// Words the animation document itself shows (its step controls). Lives in
/// core because the document is built without a BuildContext; the Flutter
/// footer uses the same words so the two always agree.
class AnimationCopy {
  const AnimationCopy._(this.language);

  final AppLanguage language;

  static AnimationCopy of(AppLanguage language) => AnimationCopy._(language);

  bool get _ar => language == AppLanguage.arabic;

  String get back => _ar ? 'رجوع' : 'Back';
  String get next => _ar ? 'التالي' : 'Next';
  String get play => _ar ? 'شغّل' : 'Play';
  String get pause => _ar ? 'وقّف' : 'Pause';
  String get stepControls => _ar ? 'التحكم في الخطوات' : 'Step controls';

  /// "Step {i} of {n}" with literal `{i}` / `{n}` placeholders, for JS.
  String get stepTemplate => _ar ? 'خطوة {i} من {n}' : 'Step {i} of {n}';

  /// Shown (script-free) if the document navigates itself away.
  String get couldntShow => _ar
      ? 'معرفتش أعرض الأنيميشن ده. اقفل الشباك وجرّب تاني.'
      : "Couldn't show this animation. Close the window and try again.";
}

/// Messages between the app and the animation frame (window.postMessage,
/// plain strings). The app sends [back], [next] and [toggle]; the document
/// sends [escape] when Esc is pressed inside it, and [playing] / [paused]
/// when its player changes state.
abstract final class AnimationMessages {
  static const back = 'zakerly:back';
  static const next = 'zakerly:next';
  static const toggle = 'zakerly:toggle';
  static const escape = 'zakerly:escape';
  static const playing = 'zakerly:playing';
  static const paused = 'zakerly:paused';
}

/// The set of canned animation shapes the mock (and, by contract, the real
/// model) can produce. See [matchAnimationTemplate].
enum AnimationTemplate { tree, growth, keyIdeas }

/// Chooses a template from the concept text alone. Deliberately ignores the
/// retrieved course chunk headings: a course about trees can have a "tree"
/// heading pulled in for an unrelated concept (e.g. "Summarize the key
/// ideas"), which previously misrouted plain summaries into the BST
/// animation. The BST template is reserved for concepts that are actually
/// about trees or binary search trees; a finance concept gets the growth
/// template; anything else - including "summarize"/"key ideas" style asks
/// and unknown concepts - falls back to the generic key-ideas template.
AnimationTemplate matchAnimationTemplate(String concept) {
  final terms = contentTerms(concept).toSet();
  bool any(Iterable<String> words) => words.any(terms.contains);

  if (any(const ['tree', 'bst', 'binary'])) return AnimationTemplate.tree;
  if (any(const ['interest', 'compound', 'invest', 'finance', 'principal', 'apr'])) {
    return AnimationTemplate.growth;
  }
  return AnimationTemplate.keyIdeas;
}

/// Asks the model to draw an HTML animation of a concept. Results are cached
/// per course + language + theme + normalised concept, so the whole class
/// shares one generation per look.
class AnimationService {
  AnimationService({
    required this.providers,
    required this.scheduler,
    required this.cache,
    required this.budget,
  });

  final ProviderRegistry providers;
  final RequestScheduler scheduler;
  final GenerationCache cache;
  final BudgetController budget;

  Future<AnimationResult> visualize(
    Course course,
    String concept, {
    AppLanguage language = AppLanguage.english,
    AnimationTheme theme = AnimationTheme.light,
  }) async {
    final key = 'animation:v2:${course.id}:${language.code}:${theme.name}:${conceptKey(concept)}';
    final hit = await cache.lookup(key);
    if (hit != null) {
      return AnimationResult(concept: concept, html: hit.value, tokens: hit.tokenCost, fromCache: true);
    }
    if (!budget.canGenerateAnimation) {
      throw AnimationLimitReached(
          'You\'ve used all ${budget.plan.animationsPerDay} new animations for today. '
          'Come back tomorrow. Ones your class already drew still open for free.',
          perDay: budget.plan.animationsPerDay);
    }

    final context = retrieve(concept, course.readyFiles.expand((f) => f.chunks), budgetTokens: 1200);
    late LlmResponse res;
    final short = concept.length > 28 ? '${concept.substring(0, 28)}…' : concept;
    final job = scheduler.submit(
      label: 'Animation · $short',
      kind: JobKind.animation,
      subject: short,
      lane: JobLane.interactive,
      estimatedTokens: 4000,
      run: () async {
        res = await providers.current.generate(LlmRequest(
          purpose: LlmPurpose.animation,
          system: Prompts.animationSystemFor(language: language, theme: theme),
          prompt: Prompts.animation(concept, context, language: language, theme: theme),
          maxOutputTokens: 6000,
        ));
        return res.totalTokens;
      },
    );
    await job.done;

    final html = extractHtml(res.text);
    budget.countAnimation();
    await cache.save(key, html, res.totalTokens);
    return AnimationResult(concept: concept, html: html, tokens: res.totalTokens, fromCache: false);
  }
}

/// Models sometimes wrap output in code fences or add prose. Keep only the
/// document.
String extractHtml(String raw) {
  var s = raw.replaceAll(RegExp(r'^```(?:html)?\s*', multiLine: true), '').replaceAll('```', '');
  final lower = s.toLowerCase();
  var start = lower.indexOf('<!doctype');
  if (start == -1) start = lower.indexOf('<html');
  if (start > 0) s = s.substring(start);
  if (start == -1) {
    s = '<!doctype html><html><body style="margin:0;background:#0b0b0f;color:#fff;'
        'font:16px system-ui;display:grid;place-items:center;height:100vh">$s</body></html>';
  }
  return s.trim();
}
