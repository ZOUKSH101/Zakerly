// Every user-facing string in the app, in English and Arabic, side by side.
//
// Dependency-free on purpose: no ARB files, no codegen. `S.of(context)`
// picks the language from the app locale (set from AppPreferences in
// app.dart). Core code that has no BuildContext hands the UI a key (an enum
// such as [WaitReason] or [TutorNotice]) and the UI turns it into words here.
//
// Arabic voice (docs/brand/BRAND.md s.6): written, not translated. Friendly
// Egyptian-leaning Arabic, English course and brand terms kept in Latin
// (Canvas, Gemini, Pro, API key), Western digits, no em dashes.
import 'package:flutter/widgets.dart';

import '../core/models.dart';
import '../core/budget.dart';
import '../core/preferences.dart';
import '../core/scheduler.dart';

class S {
  const S._(this.isArabic);

  final bool isArabic;

  static const S en = S._(false);
  static const S ar = S._(true);

  /// The strings for the app's current locale. Falls back to English when
  /// there is no Localizations ancestor (bare test harnesses).
  static S of(BuildContext context) =>
      Localizations.maybeLocaleOf(context)?.languageCode == 'ar' ? ar : en;

  static S forLanguage(AppLanguage language) => language == AppLanguage.arabic ? ar : en;

  String _t(String en, String ar) => isArabic ? ar : en;

  // ---- Arabic counting helpers -------------------------------------------

  /// Arabic number agreement: 1 and 2 use the singular and dual forms with
  /// no digit, 3 to 10 take the plural, 11 and up the singular.
  static String _arCount(int n,
      {required String one, required String two, required String few, required String many}) {
    if (n == 1) return one;
    if (n == 2) return two;
    final r = n % 100;
    return (r >= 3 && r <= 10) ? '$n $few' : '$n $many';
  }

  String _files(int n) => isArabic
      ? _arCount(n, one: 'ملف واحد', two: 'ملفين', few: 'ملفات', many: 'ملف')
      : '$n file${n == 1 ? '' : 's'}';

  String _sections(int n) => isArabic
      ? _arCount(n, one: 'جزء واحد', two: 'جزئين', few: 'أجزاء', many: 'جزء')
      : '$n section${n == 1 ? '' : 's'}';

  String _courses(int n) => isArabic
      ? _arCount(n, one: 'مادة واحدة', two: 'مادتين', few: 'مواد', many: 'مادة')
      : '$n courses';

  // ---- Brand ------------------------------------------------------------

  String get appName => 'Zakerly';
  String get appNameArabic => 'ذاكرلي';

  // ---- Workspace navigation ----------------------------------------------

  String get navCourses => _t('Courses', 'المواد');
  String get navStudy => _t('Study', 'ذاكر');
  String get navStatus => _t('Status', 'الحالة');

  // ---- Common --------------------------------------------------------------

  String get close => _t('Close', 'اقفل');
  String get send => _t('Send', 'ابعت');
  String get cancel => _t('Cancel', 'إلغاء');
  String get save => _t('Save', 'حفظ');
  String get settings => _t('Settings', 'الإعدادات');
  String get guest => _t('Guest', 'ضيف');
  String more(int n) => _t('+$n more', '+$n كمان');
  String tokensLeft(String n) => _t('$n left', 'فاضل $n');

  /// "5:01 pm" / "5:01 م".
  String clock(DateTime dt) {
    final h12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return isArabic ? '$h12:$m ${dt.hour < 12 ? 'ص' : 'م'}' : '$h12:$m ${dt.hour < 12 ? 'am' : 'pm'}';
  }

  // ---- Study modes -----------------------------------------------------------

  String modeLabel(StudyMode m) => switch (m) {
        StudyMode.explain => _t('Explain', 'اشرحلي'),
        StudyMode.socratic => _t('Guide me', 'ناقشني'),
        StudyMode.quiz => _t('Quiz me', 'امتحنّي'),
      };

  String modeTooltip(StudyMode m) => switch (m) {
        StudyMode.explain => _t('Get a clear answer', 'إجابة واضحة على طول'),
        StudyMode.socratic => _t('Work it out with hints', 'نوصل للإجابة سوا بتلميحات'),
        StudyMode.quiz => _t('Test yourself', 'اختبر نفسك'),
      };

  // ---- Study panel -----------------------------------------------------------

  String budgetPillSemantics(String n) =>
      _t('Budget: $n tokens left. Open Status', 'الرصيد: فاضل $n توكن. افتح الحالة');
  String gettingCourseReady(String code) => _t(
        'Getting $code ready. You can ask about the files that are done.',
        'بجهّز $code. تقدر تسأل في الملفات اللي خلصت.',
      );
  String get processNow => _t('Process now', 'جهّزها دلوقتي');
  String planLimitNote(String plan, int maxCourses) => _t(
        'The $plan plan covers ${_courses(maxCourses)}. Switch to Pro in Settings to open this one.',
        'باقة $plan فيها ${_courses(maxCourses)} بس. حوّل لـ Pro من الإعدادات عشان تفتح المادة دي.',
      );
  String get syncToStartTitle => _t('Sync your courses to start', 'هات موادك من Canvas ونبدأ');
  String get syncToStartBody => _t(
        "Tap Sync next to Canvas and I'll bring in your slides and readings.",
        'دوس مزامنة جنب Canvas وأنا هجيبلك السلايدز والقراءات.',
      );
  String get starterSummary => _t('Sum up the main ideas', 'لخّصلي أهم الأفكار');
  String get starterQuiz => _t('Quiz me on this week', 'امتحنّي في الأسبوع ده');
  String get starterHardest => _t('Explain the hardest part', 'اشرحلي أصعب جزء');
  String get homeTitle => _t('What are we studying today?', 'هنذاكر إيه النهارده؟');
  String homeReady(String course) =>
      _t('Ready. Ask me anything from $course.', 'خلصت. اسألني أي حاجة في $course.');
  String homeNotReady(String course) => _t(
        "Ask me anything from $course. I'll answer from your course files.",
        'اسألني أي حاجة في $course. هجاوبك من ملفات المادة بتاعتك.',
      );
  String get animateLimitTooltip =>
      _t("That's all the new animations for today", 'خلّصت الأنيميشن الجديدة بتاعة النهارده');
  String get animateTooltip =>
      _t('Draw this answer as a short animation', 'ارسم الإجابة دي في أنيميشن قصير');
  String get animateIt => _t('Animate it', 'حرّكها');
  String metaTokens(String n) => _t('$n tokens · ', '$n توكن · ');
  String metaSaved(int pct) =>
      _t('$pct% less than sending the full files', 'أقل بـ $pct% من إنك تبعت الملفات كاملة');
  String get composerFilesNotReady =>
      _t("Your files aren't ready yet. You can still ask.", 'ملفاتك لسه مش جاهزة. بس تقدر تسأل عادي.');

  /// Names the Status panel rather than a side: it is a column on desktop,
  /// a drawer on tablets and a tab on phones.
  String composerUsingFiles(int n) => _t(
        'Using ${_files(n)}. Change them in Status.',
        'بستخدم ${_files(n)}. غيّرهم من الحالة.',
      );
  String get composerNoMatch => _t(
        'Nothing in your files matches that, so this one is free.',
        'مفيش حاجة في ملفاتك عن ده، فالسؤال ده ببلاش.',
      );
  String composerEstimate(String tokens, int sections, String full) => _t(
        'About $tokens tokens from ${_sections(sections)}. The full files would cost $full.',
        'حوالي $tokens توكن من ${_sections(sections)}. الملفات كاملة كانت هتكلف $full.',
      );
  String get askTheTutor => _t('Ask the tutor', 'اسأل ذاكرلي');
  String askAbout(String code) => _t('Ask about $code…', 'اسأل في $code…');
  String get animateLastAnswer => _t('Animate the last answer', 'حرّك آخر إجابة');
  String sourceSemantics(int n, String file, String heading) =>
      _t('Source $n: $file, $heading', 'المصدر $n: $file، $heading');
  String get tutorTyping => _t('Tutor is typing', 'ذاكرلي بيكتب');

  /// Replies the tutor makes on its own, without the model.
  String tutorNotice(TutorNotice n) => switch (n) {
        TutorNotice.notFound => _t(
            "I couldn't find that in your files. Try words from your slides, or turn on more files in Status.",
            'ملقتش ده في ملفاتك. جرّب كلمات من السلايدز، أو شغّل ملفات أكتر من الحالة.',
          ),
        TutorNotice.outOfBudget => _t(
            "You've used this month's budget. Change your plan or key in Settings to keep going.",
            'خلّصت رصيد الشهر ده. غيّر الباقة أو المفتاح من الإعدادات عشان تكمّل.',
          ),
        TutorNotice.failed => _t(
            "I couldn't answer that just now. Try sending it again.",
            'معرفتش أرد دلوقتي. جرّب تبعته تاني.',
          ),
      };

  // ---- Status panel ----------------------------------------------------------

  String get budget => _t('Budget', 'الرصيد');
  String get yourKey => _t('Your key', 'مفتاحك');
  String budgetUsedSemantics(int pct) =>
      _t('$pct percent of monthly budget used', 'استخدمت $pct% من رصيد الشهر');
  String ofThisMonth(String n) => _t('of $n this month', 'من $n الشهر ده');
  String usedThisSession(String n) => _t('$n used this session', 'استخدمت $n في الجلسة دي');
  String get files => _t('Files', 'الملفات');
  String get pickCourseForFiles => _t('Pick a course to see its files', 'اختار مادة عشان تشوف ملفاتها');
  String savedThisSession(String n) => _t('Saved $n this session', 'وفّرت $n في الجلسة دي');
  String stopUsingFile(String f) => _t('Stop using $f in answers', 'متستخدمش $f في الإجابات');
  String useFile(String f) => _t('Use $f in answers', 'استخدم $f في الإجابات');
  String fileStatus(FileStatus s) => switch (s) {
        FileStatus.ready => _t('Ready', 'جاهز'),
        FileStatus.queued => _t('Waiting', 'مستني'),
        FileStatus.processing => _t('Getting ready', 'بيتجهّز'),
        FileStatus.unprocessed => _t('Not started', 'لسه مبدأش'),
        FileStatus.failed => _t("Couldn't read this file", 'معرفتش أقرا الملف ده'),
      };
  String get inProgress => _t('In progress', 'شغّال عليه');

  /// "Demo: pretend it's night (1 to 7 am)".
  String demoNight(SchedulerPolicy p) {
    if (!isArabic) return "Demo: pretend it's night (${p.windowLabel})";
    String part(int h) {
      final hh = h % 24;
      if (hh < 12) return 'الصبح';
      if (hh < 17) return 'الضهر';
      return 'بالليل';
    }

    int twelve(int h) => h % 12 == 0 ? 12 : h % 12;
    final a = p.offPeakStartHour, b = p.offPeakEndHour;
    final range = part(a) == part(b)
        ? 'من ${twelve(a)} لـ ${twelve(b)} ${part(b)}'
        : 'من ${twelve(a)} ${part(a)} لـ ${twelve(b)} ${part(b)}';
    return 'تجربة: اعتبر إننا بالليل ($range)';
  }

  String get workingOnIt => _t('Working on it now', 'شغّال عليه دلوقتي');
  String get waiting => _t('Waiting', 'مستني');
  String waitReason(WaitReason r, {required int requestsPerMinute}) => switch (r) {
        WaitReason.freeSlot => _t('Waiting for a free slot', 'مستني دور فاضي'),
        WaitReason.pacing => isArabic
            ? 'ماشي على ${_arCount(requestsPerMinute, one: 'طلب واحد', two: 'طلبين', few: 'طلبات', many: 'طلب')} في الدقيقة'
            : 'Keeping to $requestsPerMinute requests a minute',
        WaitReason.liveFirst => _t('Letting your questions go first', 'بخلّي أسئلتك تعدّي الأول'),
        WaitReason.quietMoment => _t('Waiting for a quiet moment', 'مستني وقت هادي'),
      };

  /// Row title for a scheduler job, from its kind and subject.
  String jobTitle(Job job) => switch (job.kind) {
        JobKind.process => job.subject ?? job.label,
        JobKind.answer => _t('Answer · ${job.subject}', 'إجابة · ${job.subject}'),
        JobKind.animation => _t('Animation · ${job.subject}', 'أنيميشن · ${job.subject}'),
        JobKind.other => job.label,
      };

  // ---- Course rail -----------------------------------------------------------

  String get canvas => 'Canvas';
  String get synced => _t('Synced', 'خلصت المزامنة');
  String syncedAt(String time) => _t('Synced $time', 'آخر مزامنة $time');
  String get notSyncedYet => _t('Not synced yet', 'لسه معملناش مزامنة');
  String get sync => _t('Sync', 'مزامنة');
  String get syncFailed => _t(
        "Canvas isn't answering right now. Try Sync again in a bit.",
        'Canvas مش بيرد دلوقتي. جرّب المزامنة كمان شوية.',
      );
  String get noCoursesTitle => _t('No courses yet', 'مفيش مواد لسه');
  String get noCoursesBody =>
      _t('Tap Sync above to bring them in from Canvas.', 'دوس مزامنة فوق وهاتها من Canvas.');
  String get courseGettingReady => _t('Getting ready…', 'بتتجهّز…');
  String get courseReady => _t('Ready', 'جاهزة');
  String get courseNotStarted => _t('Not started', 'لسه مبدأتش');
  String get needsPro => _t('Needs Pro', 'محتاجة Pro');
  String planCovers(String plan, int maxCourses) =>
      _t('The $plan plan covers ${_courses(maxCourses)}', 'باقة $plan فيها ${_courses(maxCourses)} بس');
  String filesFailed(int n) => isArabic ? '${_files(n)} ماتحمّلتش' : "$n didn't load";
  String readyOfTotal(int ready, int total) => _t('$ready/$total ready', '$ready/$total جاهزين');
  String get selectedSuffix => _t(', selected', '، متختارة');

  // ---- Plans -----------------------------------------------------------------

  String planName(PlanTier t) => switch (t) {
        PlanTier.free => _t('Free', 'مجانية'),
        PlanTier.pro => 'Pro',
      };

  String planPrice(PlanTier t) => switch (t) {
        PlanTier.free => _t('EGP 0', '0 جنيه'),
        PlanTier.pro => _t('Price coming soon', 'السعر قريب'),
      };

  List<String> planPerks(PlanTier t) => switch (t) {
        PlanTier.free => [
            _t('2 Canvas courses', 'مادتين من Canvas'),
            _t('250k tokens a month', '250k توكن في الشهر'),
            _t('5 new animations a day', '5 أنيميشن جديدة في اليوم'),
            _t("Processing when it's quiet", 'بجهّز ملفاتك في الأوقات الهادية'),
          ],
        PlanTier.pro => [
            _t('All your courses', 'كل موادك'),
            _t('3M tokens a month', '3M توكن في الشهر'),
            _t('100 new animations a day', '100 أنيميشن جديدة في اليوم'),
            _t('Faster processing', 'تجهيز أسرع'),
          ],
      };

  // ---- Settings --------------------------------------------------------------

  String get sectionGeneral => _t('General', 'عام');
  String get sectionPlan => _t('Plan', 'الباقة');
  String get sectionKeys => _t('Model keys', 'مفاتيح الموديلات');
  String get sectionAccount => _t('Account', 'الحساب');
  String get appearance => _t('Appearance', 'الشكل');
  String get themeSystem => _t('System', 'زي الجهاز');
  String get themeLight => _t('Light', 'فاتح');
  String get themeDark => _t('Dark', 'غامق');
  String get language => _t('Language', 'اللغة');
  String get tutorial => _t('Tutorial', 'جولة سريعة');
  String get tutorialBlurb => _t('A 30 second tour of the workspace.', 'لفّة 30 ثانية على الشاشة.');
  String get showTutorialAgain => _t('Show tutorial again', 'اعرض الجولة تاني');
  String get demoPlansFree =>
      _t('This is a demo, so switching plans is free.', 'دي نسخة تجريبية، فتغيير الباقة ببلاش.');
  String get current => _t('Current', 'الحالية');
  String switchTo(String plan) => _t('Switch to $plan', 'حوّل لـ $plan');
  String get keysIntro => _t(
        'Have your own API key? It stays on this device and only goes to that provider.',
        'عندك API key بتاعك؟ بيفضل على الجهاز ده ومبيروحش غير للشركة بتاعته.',
      );
  String get useOwnKey => _t('Use my own key', 'استخدم المفتاح بتاعي');
  String get useOwnKeySubtitle =>
      _t("Pay with your key instead of your plan's budget", 'ادفع من مفتاحك بدل رصيد الباقة');
  String monthlyCapValue(String n) => _t('Monthly cap: $n', 'الحد الشهري: $n');
  String get monthlyCap => _t('Monthly cap', 'الحد الشهري');
  String tokensPerMonth(String n) => _t('$n tokens per month', '$n توكن في الشهر');
  String keyEnding(String provider, String last4) =>
      _t('$provider key ending $last4', 'مفتاح $provider اللي آخره $last4');
  String removeKey(String provider) => _t('Remove $provider key', 'امسح مفتاح $provider');
  String get soon => _t('Soon', 'قريبًا');
  String get addKey => _t('Add key', 'ضيف مفتاح');
  String get pasteApiKey => _t('Paste API key', 'الصق الـ API key');
  String providerKeyLabel(String provider) => _t('$provider API key', 'الـ API key بتاع $provider');

  /// Second line under each provider in Model keys.
  String providerModel(String id, String fallback) => switch (id) {
        'openai' => _t('GPT models', 'موديلات GPT'),
        'anthropic' => _t('Claude models', 'موديلات Claude'),
        _ => fallback,
      };
  String get signOut => _t('Sign out', 'تسجيل الخروج');
  String get connectedDemo => _t('Connected (demo)', 'متوصّل (تجريبي)');
  String get sharedWithClass => _t('Shared with your class', 'متشارك مع دفعتك');
  String get reused => _t('Reused', 'اتستخدمت تاني');
  String get madeNew => _t('Made new', 'اتعملت جديد');
  String get reuseRate => _t('Reuse rate', 'نسبة إعادة الاستخدام');
  String tokensSaved(String n) => _t('$n tokens saved', 'وفّرت $n توكن');

  // ---- Sign in ---------------------------------------------------------------

  String get signInError => _t(
        "That didn't work. Check your email and password and try again.",
        'مانفعش. راجع الإيميل والباسورد وجرّب تاني.',
      );
  String get signInTagline => _t(
        "I already read your slides. Sign in and let's study.",
        'أنا قريت السلايدز بتاعتك خلاص. سجّل دخول ويلا نذاكر.',
      );
  String get email => _t('Email', 'الإيميل');
  String get password => _t('Password', 'الباسورد');
  String get continueLabel => _t('Continue', 'كمّل');
  String get continueWithGoogle => _t('Continue with Google', 'كمّل بحساب Google');

  // ---- Tutorial --------------------------------------------------------------

  String get tutorialSyncTitle => _t('Your courses, synced', 'موادك وصلت');
  String get tutorialSyncBody => _t(
        'I brought in your courses and files from Canvas. Tap Sync any time to get new ones.',
        'جبتلك موادك وملفاتك من Canvas. دوس مزامنة في أي وقت عشان تجيب الجديد.',
      );
  String get tutorialCoursesTitle => _t('Pick a course', 'اختار مادة');
  String get tutorialCoursesBody => _t(
        'Tap one to open it. The ring fills as I read its files.',
        'دوس على مادة تفتحها. الدايرة بتتملي وأنا بقرا ملفاتها.',
      );
  String get tutorialFilesTitle => _t('Choose what I read', 'اختار أقرا إيه');
  String get tutorialFilesBody =>
      _t('I only use the files you tick here.', 'أنا بستخدم بس الملفات اللي بتعلّم عليها هنا.');
  String get tutorialModesTitle => _t('Pick how I help', 'اختار أساعدك إزاي');
  String get tutorialModesBody => _t(
        'Explain gives you a clear answer. Guide me gives you hints so you work it out. Quiz me tests you.',
        '"اشرحلي" بيديك إجابة واضحة. "ناقشني" بيديك تلميحات عشان توصل لها بنفسك. "امتحنّي" بيختبرك.',
      );
  String get tutorialComposerTitle => _t('Ask your question', 'اسأل سؤالك');
  String get tutorialComposerBody => _t(
        "Ask anything from your slides. I'll show which file each answer came from.",
        'اسأل أي حاجة من السلايدز. وهوريك كل إجابة جاية من أنهي ملف.',
      );
  String get tutorialVisualizeTitle => _t('Watch it move', 'اتفرّج عليها بتتحرك');
  String get tutorialVisualizeBody =>
      _t('Turn my last answer into a short animation.', 'حوّل آخر إجابة ليا لأنيميشن قصير.');
  String get tutorialBudgetTitle => _t('Your budget', 'رصيدك');
  String get tutorialBudgetBody =>
      _t('This is how much you have left this month.', 'ده اللي فاضلك الشهر ده.');
  String get tutorialSettingsTitle => _t('Plans and keys', 'الباقات والمفاتيح');
  String get tutorialSettingsBody => _t(
        'Need more? Switch plans or add your own API key here.',
        'محتاج أكتر؟ غيّر الباقة أو ضيف الـ API key بتاعك من هنا.',
      );
  String tutorialSemantics(int i, int n, String title, String body) =>
      _t('Tutorial step $i of $n: $title. $body', 'الجولة، خطوة $i من $n: $title. $body');
  String stepOf(int i, int n) => _t('Step $i of $n', 'خطوة $i من $n');
  String get skip => _t('Skip', 'تخطّي');
  String get back => _t('Back', 'رجوع');
  String get next => _t('Next', 'التالي');
  String get done => _t('Done', 'تمام');

  // ---- Animation window ------------------------------------------------------

  String animationSemantics(String concept) => _t('Animation: $concept', 'أنيميشن: $concept');
  String get replay => _t('Replay', 'شغّل تاني');
  String get drawingSemantics => _t(
        'Drawing your animation. Checking if your class already has one',
        'برسم الأنيميشن بتاعك. بشوف لو دفعتك عندها واحد جاهز',
      );
  String get drawing => _t('Drawing your animation…', 'برسم الأنيميشن بتاعك…');
  String get checkingClass =>
      _t('Checking if your class already has one', 'بشوف لو دفعتك عندها واحد جاهز');
  String get limitTitle => _t("That's all for today", 'كده خلصنا النهارده');
  String limitBody(int n) => _t(
        "You've used all $n new animations for today. Come back tomorrow. "
            'Ones your class already drew still open for free.',
        'استخدمت الـ $n أنيميشن الجديدة بتوع النهارده. تعالى بكرة. '
            'اللي دفعتك رسمته قبل كده لسه بيفتح ببلاش.',
      );
  String get proPerDay => _t('Pro: 100 a day', 'Pro: 100 في اليوم');
  String get couldntDraw => _t("Couldn't draw that", 'معرفتش أرسمها');
  String get couldntDrawBody =>
      _t('Try again, or ask the question a different way.', 'جرّب تاني، أو اسأل بطريقة تانية.');
  String savedTokens(String n) => _t('Saved $n tokens', 'وفّرت $n توكن');
  String usedTokens(String n) => _t('Used $n tokens', 'استخدمت $n توكن');
  String get alreadyDrawn => _t('Already drawn for your class', 'اترسمت قبل كده لدفعتك');
  String nowFreeFor(String code) => _t('Now free for everyone in $code', 'بقت ببلاش لكل اللي في $code');
}
