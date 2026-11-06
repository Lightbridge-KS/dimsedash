import 'package:flutter/material.dart';

/// Synchronizes external draft changes without recreating the focused editor.
class FindField extends StatefulWidget {
  const FindField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.helper,
    this.hint,
    this.obscure = false,
    this.suffix,
    this.groupLabel = false,
    this.focusNode,
    this.error,
  });
  final String label, value;
  final String? helper, hint, error;
  final FocusNode? focusNode;
  final bool obscure;
  final bool groupLabel;
  final Widget? suffix;
  final ValueChanged<String> onChanged;
  @override
  State<FindField> createState() => _FindFieldState();
}

class _FindFieldState extends State<FindField> {
  late final _text = TextEditingController(text: widget.value);
  @override
  void didUpdateWidget(FindField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_text.text != widget.value) {
      _text.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final input = TextField(
      controller: _text,
      focusNode: widget.focusNode,
      obscureText: widget.obscure,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.groupLabel ? null : widget.label,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        suffixIcon: widget.suffix,
        helperText: widget.helper,
        errorText: widget.error,
        errorMaxLines: 4,
        helperMaxLines: 3,
        hintText: widget.hint,
        border: const OutlineInputBorder(),
      ),
    );
    return widget.groupLabel
        ? CriteriaGroup(
            label: widget.label,
            child: Semantics(label: widget.label, child: input),
          )
        : input;
  }
}

/// Equal heading style and spacing keep controls aligned across filter groups.
/// Help and validation remain below the controls and may grow independently.
class CriteriaGroup extends StatelessWidget {
  const CriteriaGroup({super.key, required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 12),
      child,
    ],
  );
}
