# Copy audit

Every user-facing string in `lib/**`, `web/index.html` and `web/manifest.json`, checked against the humanizer rules and the voice section of `docs/brand/BRAND.md`. Line numbers are after the edits. "Kept" means the string already passed.

## Terms (one per concept)

| Concept | Term used | Notes |
|---|---|---|
| Action that pushes a file ahead in the queue | **Process now** | Button text in the study note and the In progress card. |
| A file or course being worked on | **Getting ready** | Course tile, file status dot. "Processing" and "index" no longer appear as status words. |
| Done | **Ready** | Course tile, file status dot. |
| Not touched yet | **Not started** | Was "Not processed" on the file dot. |
| Waiting in line | **Waiting** | Was "Queued". |
| Spending allowance | **Budget** (headings), **tokens** (only as a unit: "250k tokens a month") | "Monthly token cap" became "Monthly cap". |
| Study modes | **Explain / Guide me / Quiz me** | Tooltips: "Get a clear answer", "Work it out with hints", "Test yourself". |
| Reused animation | **Already drawn for your class** | From the brand guide. Replaces "From cache" and "Cached for everyone". |

## Inventory

| file:line | before | after |
|---|---|---|
| **lib/ui/features/study/study_panel.dart** | | |
| study_panel.dart:216 | (no tooltips on mode switch) | Explain "Get a clear answer" · Guide me "Work it out with hints" · Quiz me "Test yourself" |
| study_panel.dart:287 | Budget: {n} tokens left. Open status | Budget: {n} tokens left. Open Status |
| study_panel.dart:306 | {n} left | Kept |
| study_panel.dart:326 | Getting {code} ready. You can ask about the files that are done. | Kept |
| study_panel.dart:330 | Process now | Kept |
| study_panel.dart:344 | Your plan processes one course at a time. Switch your active course in Status when you're ready for this one. | The {plan} plan covers {n} courses. Switch to Pro in Settings to open this one. (old copy pointed to a control that does not exist) |
| study_panel.dart:383 | Sync your courses to start | Kept |
| study_panel.dart:384 | Hit Sync on the left. We'll pull in your slides and readings. | Tap Sync next to Canvas and I'll bring in your slides and readings. ("on the left" was wrong on phones) |
| study_panel.dart:446 | Summarize the key ideas | Sum up the main ideas |
| study_panel.dart:447 | Quiz me on this week | Kept |
| study_panel.dart:448 | Explain the hardest concept | Explain the hardest part |
| study_panel.dart:464 | Hi! Ask me anything about {code}. I'll answer using your course files. | Hi! Ask me anything about {code}. I'll answer from your course files. |
| study_panel.dart:536 | Source: {file}, section {heading} (semantics) | Kept |
| study_panel.dart:565 | {n} tokens · full files: {m} · {p}% saved | {n} tokens · {p}% less than sending the full files |
| study_panel.dart:601 | Ask away. I'll answer with what I know so far. | Your files aren't ready yet. You can still ask. |
| study_panel.dart:602 | Using {n} files. Change them in Status. | Using {n} file/files. Change them in Status. (fixed "1 files") |
| study_panel.dart:606 | Nothing in your files matches that. You won't spend any tokens. | Nothing in your files matches that, so this one is free. |
| study_panel.dart:609 | ~{n} tokens from {k} sections · full files would be {m} | About {n} tokens from {k} section/sections. The full files would cost {m}. |
| study_panel.dart:626 | Ask the tutor (field label) | Kept |
| study_panel.dart:627 | Ask about {code}… | Kept |
| study_panel.dart:638 | Visualize the last answer | Animate the last answer |
| study_panel.dart:644 | Send | Kept |
| **lib/ui/features/status/status_panel.dart** | | |
| status_panel.dart:90 | Budget | Kept |
| status_panel.dart:91 | Your key / {plan} | Kept |
| status_panel.dart:99 | {p} percent of monthly budget used (semantics) | Kept |
| status_panel.dart:110 | {n} left | Kept |
| status_panel.dart:115 | of {n} this month | Kept |
| status_panel.dart:125 | {n} used this session | Kept |
| status_panel.dart:157 | Files | Kept |
| status_panel.dart:161 | No course selected | Pick a course to see its files |
| status_panel.dart:175 | +{n} more | Kept |
| status_panel.dart:184 | Saved {n} this session | Kept |
| status_panel.dart:216 | Exclude {file} from context | Stop using {file} in answers |
| status_panel.dart:217 | Include {file} in context | Use {file} in answers |
| status_panel.dart:236 | Ready | Kept |
| status_panel.dart:237 | Queued | Waiting |
| status_panel.dart:238 | Processing | Getting ready |
| status_panel.dart:239 | Not processed | Not started |
| status_panel.dart:240 | Failed | Couldn't read this file |
| status_panel.dart:293 | Processing (card title) | In progress |
| status_panel.dart:296 | Simulate off-peak (demo control) | Demo: pretend it's night (1 to 7 am) |
| status_panel.dart:307 | +{n} more | Kept |
| status_panel.dart:341 | Process now | Kept |
| **lib/ui/features/courses/course_rail.dart** | | |
| course_rail.dart:129 | Canvas | Kept |
| course_rail.dart:145 | Synced | Kept |
| course_rail.dart:152 | {host} · Synced {hh:mm} | Kept |
| course_rail.dart:153 | Not synced yet | Kept |
| course_rail.dart:164 | Sync | Kept |
| course_rail.dart:196 | No courses yet | Kept |
| course_rail.dart:197 | Tap Sync above to bring them in from Canvas. | Kept |
| course_rail.dart:228 | +{n} more | Kept |
| course_rail.dart:258 | Guest | Kept |
| course_rail.dart:273 | Settings | Kept |
| course_rail.dart:312 | Getting ready… | Kept |
| course_rail.dart:315 | Ready | Kept |
| course_rail.dart:317 | Not started | Kept |
| course_rail.dart:319 | Locked | Kept |
| course_rail.dart:323 | Locked · Pro (badge next to "Locked") | Pro (said "Locked" twice) |
| course_rail.dart:326 | {n} failed | {n} didn't load |
| course_rail.dart:329 | {r}/{t} ready | Kept |
| course_rail.dart:333 | . Free plan covers {n} courses. (semantics, produced ".," ) | . The {plan} plan covers {n} courses |
| **lib/ui/features/settings/settings_dialog.dart** | | |
| settings_dialog.dart:29 | Settings (semantics) | Kept |
| settings_dialog.dart:31 | Settings | Kept |
| settings_dialog.dart:32 | Plan, model keys and account (subtitle) | Removed. It repeated the three column headings right below it. |
| settings_dialog.dart:137 | Plan | Kept |
| settings_dialog.dart:144 | Payments aren't hooked up in this demo yet. | This is a demo, so switching plans is free. |
| settings_dialog.dart:167 | Current | Kept |
| settings_dialog.dart:187 | Switch to {plan} | Kept |
| settings_dialog.dart:204 | Model keys | Kept |
| settings_dialog.dart:207 | Bring your own key. It stays on this device, sent straight to the provider. | Have your own API key? It stays on this device and only goes to that provider. |
| settings_dialog.dart:216 | Use my own key | Kept |
| settings_dialog.dart:217 | Spend from your key instead of your plan | Pay with your key instead of your plan's budget |
| settings_dialog.dart:224 | Monthly cap: {n} | Kept |
| settings_dialog.dart:244 | {provider} key ending {last4} (semantics) | Kept |
| settings_dialog.dart:251 | Remove {provider} key | Kept |
| settings_dialog.dart:257 | Soon | Kept |
| settings_dialog.dart:262 | Add key | Kept |
| settings_dialog.dart:299 | Paste API key | Kept |
| settings_dialog.dart:300 | {provider} API key | Kept |
| settings_dialog.dart:311 | Cancel | Kept |
| settings_dialog.dart:318 | Save | Kept |
| settings_dialog.dart:346 | Monthly token cap (semantics) | Monthly cap |
| settings_dialog.dart:354 | {n} tokens per month (slider value) | Kept |
| settings_dialog.dart:370 | Account | Kept |
| settings_dialog.dart:377 | Sign out | Kept |
| settings_dialog.dart:386 | Appearance | Kept |
| settings_dialog.dart:390-392 | System / Light / Dark | Kept |
| settings_dialog.dart:398 | Language | Kept |
| settings_dialog.dart:402-403 | English / العربية | Kept |
| settings_dialog.dart:410 | Show tutorial again | Kept |
| settings_dialog.dart:419 | Connected (demo) | Kept |
| settings_dialog.dart:422 | Shared cache | Shared with your class |
| settings_dialog.dart:431 | Hits | Reused |
| settings_dialog.dart:432 | Misses | Made new |
| settings_dialog.dart:433 | Hit rate | Reuse rate |
| settings_dialog.dart:438 | {n} tokens saved | Kept |
| **lib/ui/features/sign_in/sign_in_screen.dart** | | |
| sign_in_screen.dart:38 | That didn't work. Check your email and password and try again. | Kept |
| sign_in_screen.dart:112-115 | Zakerly / ذاكرلي | Kept |
| sign_in_screen.dart:123 | Sign in to get back to your courses. | Kept |
| sign_in_screen.dart:139-155 | Email / Password (labels and hints) | Kept |
| sign_in_screen.dart:181 | Continue | Kept |
| sign_in_screen.dart:190 | Continue with Google | Kept |
| **lib/ui/features/tutorial/tutorial_copy.dart** | | |
| tutorial_copy.dart:24 | Tap sync to pull your courses and files from Canvas. | Tap Sync to bring in your courses and files from Canvas. |
| tutorial_copy.dart:23 | Sync your courses | Kept |
| tutorial_copy.dart:28 | Pick a course | Kept |
| tutorial_copy.dart:29 | Tap a course to open it and start studying. | Tap one to open it. |
| tutorial_copy.dart:33 | Choose what it reads | Choose what I read |
| tutorial_copy.dart:34 | Pick the files you want. That's all the tutor sees. | I only use the files you tick here. |
| tutorial_copy.dart:38 | Ask your way | Pick how I help |
| tutorial_copy.dart:39 | Explain gives you the answer. Guide me helps you figure it out yourself. Quiz me tests you. | Explain gives you a clear answer. Guide me gives you hints so you work it out. Quiz me tests you. |
| tutorial_copy.dart:44 | Type your question | Ask your question |
| tutorial_copy.dart:45 | Ask anything about your course material here. | Ask anything from your slides. I'll show which file each answer came from. |
| tutorial_copy.dart:49 | Watch it, not just read it | Watch it move (negative parallelism) |
| tutorial_copy.dart:50 | Turn any answer into a short animation. | Turn my last answer into a short animation. (the button only animates the last one) |
| tutorial_copy.dart:54 | Keep an eye on your budget | Your budget |
| tutorial_copy.dart:55 | See what you have left, right here. | This is how much you have left this month. |
| tutorial_copy.dart:59 | Add your own key | Plans and keys (the target is the Settings button) |
| tutorial_copy.dart:60 | Need more room? Add your own key any time. | Need more? Switch plans or add your own API key here. |
| **lib/ui/features/tutorial/tutorial_overlay.dart** | | |
| tutorial_overlay.dart:170 | Tutorial step {i} of {n}: {title}. {body} (semantics) | Kept |
| tutorial_overlay.dart:403 | Step {i} of {n} | Kept |
| tutorial_overlay.dart:416-435 | Skip / Back / Next / Done | Kept |
| **lib/ui/features/animation/animation_window.dart** | | |
| animation_window.dart:61 | Animation: {concept} (semantics) | Kept |
| animation_window.dart:64 | {code} Â· {name} (mojibake) | {code} · {name} |
| animation_window.dart:70 | Replay | Kept |
| animation_window.dart:82 | Drawing your animation. Checking the shared cache first (semantics) | Drawing your animation. Checking if your class already has one |
| animation_window.dart:90 | Drawing your animationâ€¦ (mojibake) | Drawing your animation… |
| animation_window.dart:95 | Checking the shared cache first | Checking if your class already has one |
| animation_window.dart:110 | Daily limit reached | That's all for today |
| animation_window.dart:112 | Pro: 100 a day | Kept |
| animation_window.dart:120 | Couldn't draw that | Kept |
| animation_window.dart:121 | Try again, or rephrase the concept. | Try again, or ask the question a different way. |
| animation_window.dart:157 | From cache · saved {n} tokens | Saved {n} tokens |
| animation_window.dart:163 | Generated · {n} tokens | Used {n} tokens |
| animation_window.dart:169 | Cached for everyone in {code} (shown in both cases) | Already drawn for your class (reused) / Now free for everyone in {code} (new) |
| **lib/ui/workspace.dart, primitives** | | |
| workspace.dart:118-120 | Courses / Study / Status | Kept |
| dialog.dart:108 | Close | Kept |
| typing_dots.dart:48 | Tutor is typing (semantics) | Kept |
| logo.dart:116-142 | Zakerly | Kept |
| **lib/core/models.dart** | | |
| models.dart:72-74 | Explain / Guide me / Quiz me | Kept |
| models.dart:79-81 | (new) | Get a clear answer / Work it out with hints / Test yourself |
| **lib/core/budget.dart** (plan cards in Settings) | | |
| budget.dart:28-29 | Free / EGP 0 | Kept |
| budget.dart:34 | 2 Canvas courses · 250k tokens / month · 5 new animations / day · Off-peak indexing | 2 Canvas courses · 250k tokens a month · 5 new animations a day · Files processed at night |
| budget.dart:37 | Pro | Kept |
| budget.dart:38 | Pricing coming soon | Price coming soon |
| budget.dart:43 | All your courses · 3M tokens / month · 100 new animations / day · Faster processing | All your courses · 3M tokens a month · 100 new animations a day · Faster processing |
| **lib/core/scheduler.dart** (In progress card, chat errors) | | |
| scheduler.dart:53 | 01:00â€“07:00 (mojibake en dash) | 1 to 7 am |
| scheduler.dart:76 | Not enough budget left (shown in chat) | You've used this month's budget. Change your plan or key in Settings to keep going. |
| scheduler.dart:135 | Waiting for a free slot | Kept |
| scheduler.dart:137 | Pacing at {n}/min | Keeping to {n} requests a minute |
| scheduler.dart:139 | Letting your questions go first | Kept |
| scheduler.dart:143 | Waiting for a quiet moment | Kept |
| **lib/core/tutor.dart** | | |
| tutor.dart:60 | I couldn't find that in your files. Try adding more on the right, or use different words from your slides. | I couldn't find that in your files. Try words from your slides, or turn on more files in Status. |
| tutor.dart:69 | Tutor · {code} (job row) | Answer · {code} |
| tutor.dart:97 | That request failed. Try again. | I couldn't answer that just now. Try sending it again. |
| **lib/core/animations.dart** | | |
| animations.dart:76 | You've hit today's {n} new animations on {plan}. Cached ones are still free. | You've used all {n} new animations for today. Come back tomorrow. Ones your class already drew still open for free. |
| animations.dart:83 | Animate · {concept} (job row) | Animation · {concept} |
| **lib/core/ingestion.dart** | | |
| ingestion.dart:54 | Process {file} (job row) | Kept. The study panel matches on this prefix. |
| **lib/core/courses.dart** | | |
| courses.dart:45 | {raw exception text} | Canvas isn't answering right now. Try Sync again in a bit. (raw error now goes to debugPrint) |
| **lib/core/providers.dart** | | |
| providers.dart:19 | OpenAI · Coming soon (next to a "Soon" badge) | OpenAI · GPT models |
| providers.dart:20 | Anthropic Claude · Coming soon (next to a "Soon" badge) | Anthropic Claude · Claude models |
| **lib/core/mock/mock_llm.dart** (demo tutor replies) | | |
| mock_llm.dart:44 | Let's work it out rather than me just telling you. | Let's work this one out together. |
| mock_llm.dart:51 | Three quick checks from your material: | Three quick questions from your files: |
| mock_llm.dart:54 | What is the key idea of "{heading}"? | What is the main point of "{heading}"? |
| mock_llm.dart:55 | Answer in the chat and I'll mark them. | Kept |
| mock_llm.dart:64 | Want to see it? Tap Visualize. | Want to see it move? Tap the animate button next to Send. |
| **lib/core/mock/mock_animations.dart** (animation player) | | |
| mock_animations.dart:51-92 | Back / Play / Pause / Next / Step X of Y | Kept |
| mock_animations.dart:118-119 | replaceAll('â€¨') / replaceAll('â€©') (mojibake, never matched) | replaceAll(' ') / replaceAll(' ') |
| mock_animations.dart:197-204 | BST step captions | Kept |
| mock_animations.dart:209 | Watch each key find its place by comparing it to the nodes above it. | Kept ("key" is the noun) |
| mock_animations.dart:233-234 | Simple interest / Compound interest | Kept |
| mock_animations.dart:265-274 | Year 1 to 10 captions | Kept |
| mock_animations.dart:279 | EGP 1,000 growing at 20% a year, simple interest compared with compound interest. | EGP 1,000 at 20% a year: simple interest next to compound interest. |
| mock_animations.dart:316 | Key idea / Add course files to see ideas pulled from your material. | No files yet / Turn on some course files and I'll pull the main ideas from them. |
| mock_animations.dart:323 | This idea just appeared: {heading}. | Idea {n}: {heading}. |
| mock_animations.dart:327 | The key ideas from your material, one at a time. | The main ideas from your files, one at a time. |
| **lib/core/prompts.dart** (LLM prompts, not UI) | | |
| prompts.dart:18 | [file Â· section] (mojibake) | [file · section] (no other prompt changes) |
| **web/** | | |
| index.html:21 | Zakerly (ذاكرلي): the study tutor that already read your slides and explains them as many times as you need. | Kept |
| index.html:37 | Zakerly (title) | Kept |
| manifest.json:8 | Zakerly (ذاكرلي): an AI study tutor that reads your Canvas courses and draws animated explanations. | Zakerly (ذاكرلي): the study tutor that already read your slides and explains them as many times as you need. |

## Left as is, on purpose

- **Mock course content** (`lib/core/mock/mock_canvas.dart`): these are the student's "lecture notes". The hyphens in them ("Week 3 - Binary Search Trees.pdf", "det(A - λI)", "extract-min") are hyphens and minus signs, not dashes. Rewriting course material would be wrong.
- **Em dashes in code comments**: about 25 left in `//` and `///` comments. Users never see them.
- **LLM prompts** (`lib/core/prompts.dart`): only the broken middle dot was fixed. There were no real em or en dashes in them.
- **Ellipses** ("Getting ready…", "Ask about CS201…", "Drawing your animation…"): these are loading or placeholder cues, not dashes, so they stay.
- **`BudgetController.sourceLabel`** ("Your API key" / "Zakerly Free"): nothing shows it.
