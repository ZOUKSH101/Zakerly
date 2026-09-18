# Zakerly: build contract

Every agent reads this first. The core layer (`lib/core/`) is finished and owned by the lead. **Read it, don't edit it.** If you need a core change, stop and report the gap.

## Product
Zakerly (ذاكرلي, "study for me") is a GenAI study workspace for university students. It's being built for the EUI GenAI for Education Hackathon 2026.
- Pulls course material straight from **Canvas** (no manual uploads)
- **Paces model requests**: live questions go first; heavy indexing waits for an off-peak window, at most N requests/min
- **Teaching-first UI**: the student is always in the driver's seat and always sees the budget left
- **BYOK**: students can plug in their own API key (Gemini first)
- **Freemium**: Free / Pro plans
- The tutor can ask the model to **draw an HTML animation**, shown in a window and cached per course

## Hard layout rule: ONE SCREEN, minimal scrolling
It's a web app. On a desktop viewport (≥1100×680) everything fits on one screen with **no page scroll**. Only the chat message list scrolls. Other lists (courses, queue) must fit by design (compact rows, cap visible items, "+N more"). Use `Expanded`/`Flexible`, never page-level `ListView`/`SingleChildScrollView`.

Layout (the integrator builds it; panels must work at these sizes):
- **≥1100 wide:** `Row[ CourseRail (272) | StudyPanel (flex) | StatusPanel (320) ]`
- **800–1099:** `Row[ CourseRail (248) | StudyPanel ]`; StatusPanel opens as an end drawer from the budget pill
- **<800:** bottom tabs: Courses / Study / Status

## Stack
- Flutter 3.47 (web), Material 3. Only extra dependency: `web` (for the iframe). No state-management packages.
- Colours with alpha: `color.withValues(alpha: x)`. **Never** `withOpacity`.
- State: services are `ChangeNotifier`s. Rebuild with `ListenableBuilder(listenable: Listenable.merge([...]), builder: ...)`.
- Access: `final s = Services.of(context);` (from `lib/core/app_services.dart`).

## Design system
- Tokens live in `lib/ui/theme.dart`; primitives in `lib/ui/primitives/` (barrel: `primitives.dart`). The design-system agent owns both.
- Everyone else composes primitives and reads tokens via `context.z` / `context.type`. No raw hex, no ad-hoc font sizes, no local restyled copies of a primitive.
- Motion follows the Apple teardown (`notes/APPLE-TECHNIQUES.md` in the claude site trainer folder):
  - Entrances are slow (~500ms) with an overshoot curve; exits are fast (150ms) with ease-in.
  - Stagger: translate 0.7s, shorter than opacity 0.9s.
  - Animate opacity/transform only. Respect `MediaQuery.disableAnimationsOf`.

## Core API (lib/core): what the UI can use
```
Services.of(context) -> AppServices:
  auth: AuthService            user (ValueListenable<AppUser?>), signInWithEmail(email, pw), signInWithGoogle(), signOut()
  lms: LmsProvider             name ('Canvas'), host ('eui.instructure.com')
  courses: CourseRepository    courses (List<Course>), syncing, lastSynced, error, sync(), byId(id)
  session: StudySession        courseId, excludedFileIds, mode (StudyMode), selectCourse(id), toggleFile(id), setMode(m), includedFileIds(course)
  ingestion: IngestionService  canIndex(course) (Free plan course limit), indexCourse(course)
  tutor: TutorService          thread(courseId) -> List<ChatMessage>, plan(course, fileIds, question, mode) -> ContextPlan, ask(course, fileIds, question, mode)
  animations: AnimationService visualize(course, concept) -> Future<AnimationResult>   (throws AnimationLimitReached)
  budget: BudgetController     plan (Plan), tier (PlanTier), useOwnKey, ownKeyCap, limit, used, remaining, fraction, sessionUsed,
                               animationsToday, canGenerateAnimation, sourceLabel, history (List<UsageEntry>), setTier, setUseOwnKey, setOwnKeyCap
  scheduler: RequestScheduler  jobs, open, finished, runningCount, requestsThisMinute, prioritize(job), setSimulateOffPeak(bool),
                               policy (requestsPerMinute, maxConcurrent, windowLabel, simulateOffPeak, isOffPeak(DateTime))
  cache: GenerationCache       hits, misses, tokensSaved, hitRate
  providers: ProviderRegistry  activeId, active (ProviderInfo), hasKey(id), maskedKey(id), saveKey(id, key), removeKey(id), setActive(id)
Constants: plans (Map<PlanTier, Plan>), providerCatalog (List<ProviderInfo>)
Models: Course(id, code, name, term, files, readyFiles, readyCount, isFullyIndexed, hasPendingWork, hasStarted)
        CourseFile(id, name, kind, sourceTokens, status: FileStatus, summary, chunks, error)
        ChatMessage(author: Author.student|tutor, text, pending, failed, citations: List<Citation(fileName, heading)>, tokens, naiveTokens)
        ContextPlan(chunks, promptTokens, naiveTokens)   Job(label, lane: JobLane, state: JobState, waitReason, error, tokensUsed, estimatedTokens)
        Plan(name, price, monthlyTokens, maxCourses, animationsPerDay, priorityProcessing, perks)
        AnimationResult(concept, html, tokens, fromCache)
Util: formatTokens(int) -> '12.4k'
```
Every `CourseRepository`, `StudySession`, `TutorService`, `BudgetController`, `RequestScheduler`, `GenerationCache` and `ProviderRegistry` is a `ChangeNotifier`.

## Feature ownership (one builder each, under lib/ui/features/<dir>/)
| Dir | Public widget / function | Owner |
|---|---|---|
| `sign_in/` | `SignInScreen()` | builder A |
| `courses/` | `CourseRail({required VoidCallback onOpenSettings})` | builder B |
| `study/` | `StudyPanel({required void Function(Course, String concept) onVisualize, VoidCallback? onOpenStatus})` | builder C |
| `status/` | `StatusPanel()` | builder D |
| `settings/` | `Future<void> showSettingsDialog(BuildContext)` | builder E |
| `animation/` | `Future<void> showAnimationWindow(BuildContext, {required Course course, required String concept})` | builder F |

The integrator owns `lib/main.dart`, `lib/app.dart` and `lib/ui/workspace.dart`.

## Verify
`flutter analyze` must be clean, and `flutter build web` must succeed. There is no test suite; analyze + build is the gate.
