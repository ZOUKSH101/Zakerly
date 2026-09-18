import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'pressable.dart';

/// iMessage-style message field: one rounded surface that grows from one to
/// [ZLayout.composerMaxLines] lines, with any [actions] and the round send
/// button inside it on the trailing edge.
///
/// Enter sends and Shift+Enter adds a new line. Enter never inserts a line
/// break on its own, even while sending is blocked, and it is left alone
/// while an input method is composing.
class ZComposer extends StatefulWidget {
  const ZComposer({
    super.key,
    required this.controller,
    required this.onSend,
    required this.canSend,
    this.focusNode,
    this.hint,
    this.semanticLabel,
    this.actions = const [],
    this.sendTooltip = 'Send',
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool canSend;
  final FocusNode? focusNode;
  final String? hint;

  /// Accessible name for the text field, e.g. "Ask the tutor".
  final String? semanticLabel;

  /// Small controls shown before the send button (e.g. an animate button).
  final List<Widget> actions;
  final String sendTooltip;

  @override
  State<ZComposer> createState() => _ZComposerState();
}

class _ZComposerState extends State<ZComposer> {
  FocusNode? _ownNode;
  FocusNode get _node => widget.focusNode ?? (_ownNode ??= FocusNode());
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(covariant ZComposer old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _ownNode)?.removeListener(_onFocus);
      _node.addListener(_onFocus);
    }
  }

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    _ownNode?.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (mounted && _focused != _node.hasFocus) setState(() => _focused = _node.hasFocus);
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key != LogicalKeyboardKey.enter && key != LogicalKeyboardKey.numpadEnter) {
      return KeyEventResult.ignored;
    }
    if (HardwareKeyboard.instance.isShiftPressed) return KeyEventResult.ignored;
    if (widget.controller.value.composing.isValid) return KeyEventResult.ignored;
    if (widget.canSend) widget.onSend();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    final type = context.type;
    return AnimatedContainer(
      duration: ZMotion.medium,
      curve: ZMotion.standard,
      padding: const EdgeInsetsDirectional.fromSTEB(ZSpace.s20, ZSpace.s8, ZSpace.s8, ZSpace.s8),
      decoration: BoxDecoration(
        color: z.raised,
        borderRadius: BorderRadius.circular(ZRadius.xl),
        border: Border.all(
          color: _focused ? z.accent : z.hairline,
          width: _focused ? 1.5 : 1,
        ),
        boxShadow: ZShadow.card(Theme.of(context).brightness),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Focus(
              canRequestFocus: false,
              skipTraversal: true,
              onKeyEvent: _onKey,
              child: Semantics(
                label: widget.semanticLabel,
                child: TextField(
                  controller: widget.controller,
                  focusNode: _node,
                  minLines: 1,
                  maxLines: ZLayout.composerMaxLines,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  cursorColor: z.accent,
                  style: type.bodyLarge?.copyWith(color: z.text),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: type.bodyLarge?.copyWith(color: z.textTertiary),
                    filled: false,
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    // Centres one line of 15/1.4 text on the 36px buttons.
                    contentPadding: const EdgeInsets.symmetric(vertical: 7.5),
                  ),
                ),
              ),
            ),
          ),
          for (final a in widget.actions) ...[
            const SizedBox(width: ZSpace.s4),
            SizedBox(height: 36, child: Center(child: a)),
          ],
          const SizedBox(width: ZSpace.s8),
          _SendButton(
            enabled: widget.canSend,
            tooltip: widget.sendTooltip,
            onPressed: widget.onSend,
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.enabled, required this.tooltip, required this.onPressed});

  final bool enabled;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    return Tooltip(
      message: tooltip,
      child: Pressable(
        onTap: enabled ? onPressed : null,
        semanticLabel: tooltip,
        child: AnimatedContainer(
          duration: ZMotion.medium,
          curve: ZMotion.standard,
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: enabled ? z.accent : z.raised2,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_upward_rounded,
            size: ZIcon.lg,
            color: enabled ? z.onAccent : z.textTertiary,
          ),
        ),
      ),
    );
  }
}
