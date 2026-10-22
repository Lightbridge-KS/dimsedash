import 'package:flutter/material.dart';

Widget queryCard(List<Widget> children) => Card(
  margin: EdgeInsets.zero,
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  ),
);
Widget queryNotice(BuildContext context, String text) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 8),
  child: Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(text),
  ),
);
Widget queryIdentifier(BuildContext context, String text, bool reveal) =>
    Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 12),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Text(
        reveal ? text : 'Identifier values masked. Use Reveal values to inspect the synthetic request.',
        style: const TextStyle(fontFamily: 'monospace'),
      ),
    );
String querySensitive(String? value, bool reveal) => value == null
    ? 'Not returned'
    : reveal
    ? value
    : '••••••';

Future<void> showQueryDialog(BuildContext context, String title, Widget body) =>
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
