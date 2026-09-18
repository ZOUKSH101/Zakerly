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

/// A tiny, script-free document shown in place of the animation if it ever
/// navigates itself away. [message] is HTML-escaped here.
String blockedFrameDocument(
  String message, {
  required String lang,
  required bool rtl,
  required String background,
  required String color,
}) {
  final safe = message
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
  return withNoNetworkCsp('<!doctype html><html lang="$lang" dir="${rtl ? 'rtl' : 'ltr'}">'
      '<head><meta charset="utf-8"></head>'
      '<body style="margin:0;height:100vh;display:grid;place-items:center;'
      'font:15px system-ui,sans-serif;color:$color;background:$background">'
      '<p style="margin:24px;text-align:center">$safe</p></body></html>');
}

/// Sends string messages into an [HtmlFrame]'s document (postMessage).
class HtmlFrameController {
  web.HTMLIFrameElement? _iframe;

  /// Posts [message] to the frame's window. The frame has an opaque origin
  /// (sandbox without allow-same-origin), so the target origin is '*'; the
  /// messages carry no data beyond a fixed command string.
  void send(String message) {
    _iframe?.contentWindow?.postMessage(message.toJS, '*'.toJS);
  }

  /// Moves keyboard focus into the frame.
  void focus() => _iframe?.focus();
}

/// Renders model-generated HTML inside a sandboxed iframe. Web only.
///
/// [html] is rendered once, when the underlying iframe element is created —
/// it is fixed for the lifetime of a given [HtmlFrame] instance. To show new
/// or changed content, mount a new instance with a different `key` (e.g. a
/// [ValueKey] derived from the content) rather than relying on rebuilds.
///
/// [onMessage] receives string messages the document posts to its parent
/// (only from this frame's own window, only strings in [acceptedMessages]).
class HtmlFrame extends StatefulWidget {
  const HtmlFrame({
    super.key,
    required this.html,
    required this.title,
    required this.blockedDocument,
    this.controller,
    this.onMessage,
    this.acceptedMessages = const {},
  });

  final String html;

  /// Accessible iframe title, e.g. "Animation: binary search trees".
  final String title;

  /// Script-free document loaded once if [html] navigates itself away
  /// (see [blockedFrameDocument]).
  final String blockedDocument;

  final HtmlFrameController? controller;
  final ValueChanged<String>? onMessage;
  final Set<String> acceptedMessages;

  @override
  State<HtmlFrame> createState() => _HtmlFrameState();
}

class _HtmlFrameState extends State<HtmlFrame> {
  web.HTMLIFrameElement? _iframe;
  JSFunction? _listener;

  @override
  void dispose() {
    final l = _listener;
    if (l != null) web.window.removeEventListener('message', l);
    if (identical(widget.controller?._iframe, _iframe)) widget.controller?._iframe = null;
    super.dispose();
  }

  void _onWindowMessage(web.MessageEvent event) {
    final iframe = _iframe;
    if (iframe == null || !mounted) return;
    // Only this frame's own window, and only known command strings.
    final source = event.source;
    final own = iframe.contentWindow;
    if (source == null || own == null || !source.strictEquals(own).toDart) return;
    final data = event.data;
    if (data == null || !data.isA<JSString>()) return;
    final text = (data as JSString).toDart;
    if (!widget.acceptedMessages.contains(text)) return;
    widget.onMessage?.call(text);
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView.fromTagName(
      tagName: 'iframe',
      onElementCreated: (Object e) {
        final iframe = e as web.HTMLIFrameElement;
        _iframe = iframe;
        widget.controller?._iframe = iframe;
        final listener = ((web.MessageEvent m) => _onWindowMessage(m)).toJS;
        _listener = listener;
        web.window.addEventListener('message', listener);
        final sandboxedHtml = withNoNetworkCsp(widget.html);
        var loadCount = 0;
        var blocked = false;

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
        iframe.setAttribute('title', widget.title);
        // The frame stays in the Tab order so keyboard users can reach the
        // player's own buttons. Esc still closes the window from inside:
        // the document posts AnimationMessages.escape to us (see onMessage),
        // and the dialog footer mirrors Back / Play / Next in Flutter.
        iframe.tabIndex = 0;
        iframe.style.border = '0';
        iframe.style.width = '100%';
        iframe.style.height = '100%';

        // The sandbox still lets the document navigate itself
        // (location.href, an <a> click, a meta-refresh we missed) which
        // would replace our CSP-armoured srcdoc with whatever it navigated
        // to. That navigation fires its own 'load' event, so the first load
        // past the initial one means it happened: swap in the script-free
        // "couldn't show this" document once, and ignore every load after
        // (re-setting the original srcdoc would let it navigate again,
        // looping forever).
        iframe.addEventListener('load', ((web.Event _) {
          loadCount++;
          if (loadCount > 1 && !blocked) {
            blocked = true;
            iframe.setAttribute('srcdoc', widget.blockedDocument);
          }
        }).toJS);
      },
    );
  }
}
