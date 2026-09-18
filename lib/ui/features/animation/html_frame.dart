import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Injects a network-blocking Content-Security-Policy `<meta>` tag into
/// [html], and strips any `<meta http-equiv="refresh">` tag (which could
/// otherwise navigate the frame to an external URL, bypassing the CSP).
///
/// The CSP tag is inserted right after a leading doctype (and any leading
/// comments) when present, else at the very start of the document.
/// Searching for `<head>` instead would be unreliable — it can false-match
/// `<header>` and land the tag in `<body>`, where browsers ignore it — and
/// wouldn't help documents with no explicit `<head>` at all (doctype-quirks
/// mode). Inserting at the very front guarantees the CSP is parsed before
/// anything else. Pure and testable in isolation from the widget below.
String withNoNetworkCsp(String html) {
  const csp = '<meta http-equiv="Content-Security-Policy" '
      'content="default-src \'none\'; script-src \'unsafe-inline\'; '
      'style-src \'unsafe-inline\'; img-src data: blob:; font-src data:">';

  final stripped = html.replaceAll(
    RegExp(r'<meta[^>]*http-equiv\s*=\s*["\x27]?refresh["\x27]?[^>]*>', caseSensitive: false),
    '',
  );

  final lead = RegExp(r'^\s*(?:<!--[\s\S]*?-->\s*)*<!doctype[^>]*>', caseSensitive: false)
      .firstMatch(stripped);
  final at = lead?.end ?? 0;
  return stripped.substring(0, at) + csp + stripped.substring(at);
}

/// Renders model-generated HTML inside a sandboxed iframe. Web only.
///
/// [html] is rendered once, when the underlying iframe element is created —
/// it is fixed for the lifetime of a given [HtmlFrame] instance. To show new
/// or changed content, mount a new instance with a different `key` (e.g. a
/// [ValueKey] derived from the content) rather than relying on rebuilds.
class HtmlFrame extends StatelessWidget {
  const HtmlFrame({super.key, required this.html, required this.title});

  final String html;

  /// Accessible iframe title, e.g. "Animation: binary search trees".
  final String title;

  @override
  Widget build(BuildContext context) {
    return HtmlElementView.fromTagName(
      tagName: 'iframe',
      onElementCreated: (Object e) {
        final iframe = e as web.HTMLIFrameElement;
        final sandboxedHtml = withNoNetworkCsp(html);
        var loadCount = 0;

        // SECURITY: 'allow-scripts' only — no allow-same-origin,
        // allow-top-navigation, allow-forms or allow-popups. A CSP baked
        // into the srcdoc blocks the document's own network access
        // (default-src 'none'), referrerpolicy stops referrer leakage, and
        // an empty 'allow' revokes every delegated permissions-policy
        // feature. Together these keep the generated document — which is
        // cached and shared course-wide, so a single bad generation could
        // otherwise try to phish or exfiltrate — in an opaque origin with
        // no access to this app, its storage, the network, or the user's
        // API keys.
        iframe.setAttribute('sandbox', 'allow-scripts');
        iframe.setAttribute('referrerpolicy', 'no-referrer');
        iframe.setAttribute('allow', '');
        iframe.setAttribute('srcdoc', sandboxedHtml);
        iframe.setAttribute('title', title);
        // tabIndex = -1 keeps Tab from ever focusing the frame, so keyboard
        // users can always reach Esc / the dialog's Close button without
        // tabbing into it. A direct click inside the frame can still move
        // focus there, though — while focus is inside, Esc may not reach
        // the dialog until focus returns to something outside the frame.
        iframe.tabIndex = -1;
        iframe.style.border = '0';
        iframe.style.width = '100%';
        iframe.style.height = '100%';

        // The sandbox still lets the document navigate itself
        // (location.href, an <a> click, a meta-refresh we missed) which
        // would replace our CSP-armoured srcdoc with whatever it navigated
        // to. The resulting navigation fires its own 'load' event, so any
        // load past the first is exactly that — slam the original
        // sandboxed document straight back.
        iframe.addEventListener('load', ((web.Event _) {
          loadCount++;
          if (loadCount > 1) {
            iframe.setAttribute('srcdoc', sandboxedHtml);
          }
        }).toJS);
      },
    );
  }
}
