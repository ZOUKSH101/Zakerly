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
20. VERIFIED by lead (hands-on): light mode, Arabic RTL at 1440 and 375, the tour with all 8 steps, and the two-pane settings all work. Round 2 issues are below.

# Round 2 (lead hands-on QA after the Arabic pass)
21. Citation pills render as full-width bars on their own line under each paragraph (seen at 375px in Arabic; check LTR and desktop too). They must be small inline superscript pills that flow with the text (WidgetSpan with PlaceholderAlignment.aboveBaseline or baseline, fixed small size).
    FIXED (builder B): cause was `Container(alignment: center)` inside the WidgetSpan, which grows to the line's full width. Now the `ZCiteMark` primitive (16px tall, sizes to its number via `Align(widthFactor: 1)`) in a top-aligned WidgetSpan. Tests check every mark is under 32px wide, LTR at 900px and RTL at 375px.
22. On narrow layouts (bottom tabs) the composer caption says files are "on the right" (EN) / "on the left" (AR), but they live in the Status tab. Make the caption depend on layout: wide = direction hint, narrow = "Pick files in Status" (AR: "اختار الملفات من الحالة").
    SUPERSEDED/FIXED (builder B): one caption at every width, no direction: "Using N files. Change them in Status." (AR: "بستخدم … غيّرهم من الحالة.").
23. Tutorial scrim in light mode is too faint (about 35% dim). The spec is about 70% black in both themes. The dark scrim and lit cutout is the whole point of the NBE-style tour.
24. Tutorial keyboard: Right arrow didn't advance after clicking Next (focus leaves the overlay after a click). Keep focus in the overlay (FocusScope with autofocus, and refocus after button taps).
25. Landing glow: the Hibiscus wash shows faint square edges on dark. Use a radial gradient that fades fully to transparent inside its box, or a larger box.
    FIXED (builder B): the wash now eases out over five stops and is fully transparent by 85% of its radius, so neither its box nor a phone's screen edge (at 375px the edge sits at ~91% of the radius) cuts through visible color. Needs a hands-on look on dark to confirm.
26. When the language is switched in Settings, the dialog should stay open and update in place (it does). Also verify that switching back to English from Arabic works (one tap didn't seem to register; possibly the segmented control's hit area in RTL).
    CHECKED (builder B), no fix: a widget test with app.dart's wiring (the MaterialApp rebuilds on the language change) switches EN to AR and back to EN with one tap each, and the dialog stays open. ZSegmented's hit areas are correct in RTL (each segment is a full-width `Pressable`, and the thumb is directional). Could not reproduce. If it still happens in the browser, it is likely the first tap landing during the ~200ms theme cross-fade after the Arabic switch, not the hit area.
