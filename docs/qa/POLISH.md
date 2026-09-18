# Polish list from hands-on QA (1440x900, dark)

Found by clicking through the running app on 2026-09-18. Each item is a real defect or a clear miss against the brand and Apple bar.

## Landing
1. The logo mark isn't shown. Only the wordmark text is. Use the big ZLogo mark above the headline so the draw-on animation is the first thing people see.
2. The form is small and floats in a big void. Use a larger headline and full-width buttons at the form width. Add one quiet brand touch, like a soft Hibiscus glow behind the mark.
3. "Continue with Google" is low contrast in dark mode.

## Onboarding
4. The tutorial starts before any courses exist. Only 5 of 8 steps show, and "Pick a course" spotlights an empty list. In the demo, sync the mock courses before the tour (or have the tour's first step run Sync), so every step has a real target.

## Course rail
5. The "Locked · Pro" badge squeezes the course name to "Introd...". Put the lock on its own line or use a small lock icon only.
6. "eui.instructure.com · Sy..." is truncated. Shorten it to "Synced 5:01 pm", with the host in a tooltip.

## Study / chat
7. When the thread is empty, the greeting card is small in the corner of a huge empty area. Make the empty thread feel like a home screen: a large centered "What are we studying today?" with the course name, then the starter chips centered below.
8. Tapping a starter chip only fills the composer. It should send right away.
9. Enter doesn't send. Enter should send and Shift+Enter should add a new line.
10. The answer shows raw citations inline, like "[Week 3 - Binary Search Trees.pdf · Deleting a key]". Render each one as a small numbered superscript pill that matches the source list under the answer. Show the source list once, deduplicated.
11. The composer is small (one line, thin). Make it an iMessage-style rounded field that grows to 5 lines, with the send button inside it.
12. The "Visualize" icon in the composer isn't recognizable. Use a labeled pill ("Animate it") on the latest answer as well as the composer icon.

## Status column
13. File names are truncated hard ("Week 3 - Binary Search ..."). Allow 2 lines.
14. The Processing rows truncate "Waiting for a q...". Show the reason as a tooltip and keep only the dot plus the file name.

## Animation window
15. FIXED by lead: the frame only got half the height (a Flexible badge row split the Column). The dialog is also bigger now (up to 1280x880).
16. Check that the key-ideas template content is large and centered at this size (the text was tiny at the top-left).
17. When the dialog closes, it leaves a ghost of the iframe content for about 1s over the chat. Hide the platform view as soon as the pop starts.

## Settings
18. The plan cards take the whole dialog, so Appearance and Language are hidden below the fold. Use a two-pane settings layout (left list: General, Plan, Model keys, Account; right: content), with General (Appearance, Language, Show tutorial again) first.
19. "Off-peak indexing" is still a Free perk string (core/budget.dart). It should say "Processing when it's quiet".

## Light mode, Arabic, narrow widths
20. Not yet verified. Must check light mode, Arabic RTL, and 1024px / 390px widths after the fixes.
