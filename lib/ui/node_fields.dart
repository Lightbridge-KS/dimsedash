import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';

/// Presentation only: callers own drafts, validation and persistence.
class NodeFields extends StatelessWidget {
  const NodeFields({
    super.key,
    required this.controllers,
    required this.environment,
    required this.onEnvironmentChanged,
    required this.errors,
    this.enabled = true,
  });

  final Map<String, TextEditingController> controllers;
  final NodeEnvironment environment;
  final ValueChanged<NodeEnvironment> onEnvironmentChanged;
  final Map<String, String> errors;
  final bool enabled;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        for (final (key, label, number) in [
          ('label', 'Node name', false),
          ('calledAe', 'Called AE Title', false),
          ('host', 'PACS IP address / host', false),
          ('pacsPort', 'PACS port', true),
        ])
          SizedBox(
            width: constraints.maxWidth.clamp(0, 300),
            child: TextField(
              key: ValueKey(key),
              controller: controllers[key],
              enabled: enabled,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: number ? TextInputType.number : TextInputType.text,
              decoration: InputDecoration(
                labelText: label,
                errorText: errors[key],
                errorMaxLines: 3,
              ),
            ),
          ),
        SizedBox(
          width: constraints.maxWidth.clamp(0, 300),
          child: DropdownButtonFormField<NodeEnvironment>(
            isExpanded: true,
            key: ValueKey(environment),
            initialValue: environment,
            decoration: const InputDecoration(labelText: 'Environment'),
            items: [
              for (final value in NodeEnvironment.values)
                DropdownMenuItem(value: value, child: Text(value.name)),
            ],
            onChanged: enabled
                ? (value) {
                    if (value != null) onEnvironmentChanged(value);
                  }
                : null,
          ),
        ),
      ],
    ),
  );
}

class NodeEnvironmentBadge extends StatelessWidget {
  const NodeEnvironmentBadge(this.environment, {super.key});
  final NodeEnvironment environment;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: environment == NodeEnvironment.production
            ? colors.tertiaryContainer
            : colors.secondaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        environment == NodeEnvironment.production ? 'Production' : 'Test',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: environment == NodeEnvironment.production
              ? colors.onTertiaryContainer
              : colors.onSecondaryContainer,
        ),
      ),
    );
  }
}
