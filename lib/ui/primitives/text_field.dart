import 'package:flutter/material.dart';

import '../theme.dart';

/// Standard text input. Style/decoration comes from the theme's
/// [InputDecorationThemeData]; this widget just wires the tokens' text style.
class ZTextField extends StatelessWidget {
  const ZTextField({
    super.key,
    this.controller,
    this.hint,
    this.label,
    this.obscure = false,
    this.onSubmitted,
    this.maxLines = 1,
    this.enabled = true,
    this.suffix,
    this.autofocus = false,
    this.autofillHints,
    this.keyboardType,
    this.textInputAction,
    this.focusNode,
  });

  final TextEditingController? controller;
  final String? hint;
  /// Optional floating label (`InputDecoration.labelText`). Null keeps the
  /// previous hint-only look.
  final String? label;
  final bool obscure;
  final ValueChanged<String>? onSubmitted;
  final int maxLines;
  final bool enabled;
  final Widget? suffix;
  final bool autofocus;
  final Iterable<String>? autofillHints;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    return TextField(
      controller: controller,
      obscureText: obscure,
      enableSuggestions: !obscure,
      autocorrect: !obscure,
      onSubmitted: onSubmitted,
      maxLines: obscure ? 1 : maxLines,
      enabled: enabled,
      autofocus: autofocus,
      autofillHints: autofillHints,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      focusNode: focusNode,
      cursorColor: z.accent,
      style: context.type.bodyLarge?.copyWith(color: z.text),
      decoration: InputDecoration(
        hintText: hint,
        labelText: label,
        suffixIcon: suffix,
      ),
    );
  }
}
