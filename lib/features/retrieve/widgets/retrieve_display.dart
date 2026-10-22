import 'package:flutter/material.dart';

Widget retrieveDisclosure(
  Map<String, bool> expanded,
  String key,
  String title,
  List<Widget> children,
) => ExpansionTile(
  key: ValueKey(key),
  initiallyExpanded: expanded[key] ?? false,
  onExpansionChanged: (v) => expanded[key] = v,
  tilePadding: EdgeInsets.zero,
  title: Text(title),
  children: [
    Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  ],
);
Widget retrievePanel(
  BuildContext context,
  String title,
  List<Widget> children,
) => Card.outlined(
  margin: const EdgeInsets.only(bottom: 16),
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  ),
);
Widget retrieveNotice(BuildContext context, String text) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 12),
  child: Text(
    text,
    style: TextStyle(color: Theme.of(context).colorScheme.primary),
  ),
);
String retrieveValue(String value, bool reveal) =>
    reveal ? value : 'Hidden · use Reveal values';
