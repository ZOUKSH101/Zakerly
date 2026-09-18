import 'budget.dart';
import 'cache.dart';
import 'models.dart';
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
  const AnimationLimitReached(this.message);
  final String message;
  @override
  String toString() => message;
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
/// per course + normalised concept, so the whole class shares one generation.
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

  Future<AnimationResult> visualize(Course course, String concept) async {
    final key = 'animation:v1:${course.id}:${conceptKey(concept)}';
    final hit = await cache.lookup(key);
    if (hit != null) {
      return AnimationResult(concept: concept, html: hit.value, tokens: hit.tokenCost, fromCache: true);
    }
    if (!budget.canGenerateAnimation) {
      throw AnimationLimitReached(
          'You\'ve used all ${budget.plan.animationsPerDay} new animations for today. '
          'Come back tomorrow. Ones your class already drew still open for free.');
    }

    final context = retrieve(concept, course.readyFiles.expand((f) => f.chunks), budgetTokens: 1200);
    late LlmResponse res;
    final job = scheduler.submit(
      label: 'Animation · ${concept.length > 28 ? '${concept.substring(0, 28)}…' : concept}',
      lane: JobLane.interactive,
      estimatedTokens: 4000,
      run: () async {
        res = await providers.current.generate(LlmRequest(
          purpose: LlmPurpose.animation,
          system: Prompts.animationSystem,
          prompt: Prompts.animation(concept, context),
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
