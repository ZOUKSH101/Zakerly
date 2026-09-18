# Polish list from hands-on QA (1440x900, dark)

Found by clicking through the running app on 2026-09-18. Each item is a real defect or a clear miss against the brand and Apple bar.

## Landing
1. FIXED: the 72px ZLogo sits above the headline and writes itself on first load (`sign_in_screen.dart` `_GlowingMark`).
2. FIXED: 44px hero wordmark (new `ZType.hero`), a one-line voice subline, 48px full-width buttons (`ZButton` gained `size: lg` and `expand`), and a faint Hibiscus wash on the page behind the mark (never on the tile).
3. FIXED: tonal and plain buttons now use `accentText` (#FF7AA2 in dark, 7:1), so "Continue with Google" reads clearly. Accent badges, selected icon buttons and focus rings follow the same rule.

## Onboarding
4. FIXED: the workspace syncs Canvas on sign-in (shared `syncAndStartCourses` in `courses/course_sync.dart`), then starts the tour, so all 8 steps have real targets in order: sync, courses, files, modes, composer, animate, budget, settings. Step 1 copy now says the courses are already in.

## Course rail
5. FIXED: the badge is gone. Locked courses show a small lock icon (tooltip explains the plan) and "Needs Pro" in the status line; the spinner that also squeezed names is gone too (the ring shows progress).
6. FIXED: the line reads "Synced 5:01 pm" with the host in a tooltip. It also flashes "Synced" after the sign-in sync, not only after a button tap.
   Also: the course-ready moment is wired. When a course finishes, its ring turns Mint and the amber `ZSpark` hops off it.

## Study / chat
7. FIXED: an empty thread is a home screen: centered "What are we studying today?", "Ready. Ask me anything from Data Structures." (or the not-yet-ready variant), and three centered starter chips (new `ZChip` primitive) with a staggered entrance.
8. FIXED: a starter chip sends right away.
9. FIXED: Enter sends, Shift+Enter adds a line, and Enter is ignored while an input method is composing (`ZComposer`).
10. FIXED: `citations.dart` parses "[file · section]" markers into numbered superscript pills (tooltip shows file and section) matched to one deduplicated source list under the answer. Falls back to the retrieved sections when an answer has no markers. Unit tested.
11. FIXED: new `ZComposer` primitive: a rounded field that grows from 1 to 5 lines, with the animate icon and a round Hibiscus send button inside it.
12. FIXED: the latest answer carries an "Animate it" pill (play icon); the composer icon uses the same play icon and tooltip. The mock tutor now says "Tap Animate it."

## Status column
13. FIXED: file names wrap to 2 lines; the row fitting measures each name so "+N more" still keeps the column on one screen.
14. FIXED: In progress rows show only a dot (spinner while running) and the file name; the wait reason is a tooltip, and Process now became a compact icon button with the same tooltip.

## Animation window
15. FIXED by lead: the frame only got half the height (a Flexible badge row split the Column). The dialog is also bigger now (up to 1280x880).
16. FIXED: the key-ideas template centers its list at up to 62em wide, sizes type from 15 to 24px with the frame (titles 1.25x), and dims past ideas so the current one leads. Titles, sublines and captions scale up in every template.
17. FIXED: the window listens to its route animation and swaps the iframe for a plain surface on the first frame of the exit, so no ghost is left over the chat.

## Settings
18. FIXED: two-pane layout: General (Appearance, Language, Show tutorial again), Plan (cards side by side), Model keys, Account. Fits without scrolling at 1440x900; under 600px of dialog width the list becomes a row of tabs and panes scroll on their own. "Show tutorial again" now closes Settings first so the tour lights up the real panels.
19. FIXED: the Free perk reads "Processing when it's quiet".

## Light mode, Arabic, narrow widths
20. Not yet verified. Must check light mode, Arabic RTL, and 1024px / 390px widths after the fixes.
