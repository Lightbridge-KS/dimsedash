import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';

String queryValue(
  QueryMatch row,
  int tag,
  bool reveal, {
  bool sensitive = false,
}) {
  final a = row.attribute(tag);
  if (a == null) return 'Not returned';
  if (a.decodeLimited) return 'Decode limited · unsupported character set';
  if (a.text.isEmpty) return 'Empty';
  return sensitive && !reveal ? '••••' : a.text;
}

Future<void> inspectQueryMatch(
  BuildContext context,
  QueryMatch row,
  bool reveal,
  QueryMatch? parent,
) => showDialog<void>(
  context: context,
  builder: (_) => _Inspection(row: row, reveal: reveal, parent: parent),
);

class _Inspection extends StatefulWidget {
  const _Inspection({required this.row, required this.reveal, this.parent});
  final QueryMatch row;
  final QueryMatch? parent;
  final bool reveal;
  @override
  State<_Inspection> createState() => _InspectionState();
}

class _InspectionState extends State<_Inspection> {
  String _search = '';
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Inspect returned metadata'),
    content: SizedBox(
      width: 680,
      height: 440,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Search metadata · tag or name',
            ),
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
          ),
          Expanded(
            child: ListView(
              children: [
                const Text(
                  'Missing = not returned. Empty = present with no value. Decode-limited text is not a verified reading.',
                ),
                ..._attributes(widget.row.attributes),
                if (widget.parent != null)
                  ExpansionTile(
                    title: const Text(
                      'Inherited parent metadata · not returned by this query',
                    ),
                    children: _attributes(widget.parent!.attributes),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close'),
      ),
    ],
  );
  List<Widget> _attributes(List<QueryAttribute> attributes) => [
    for (final a in attributes)
      if (_matches(a))
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: a.items.isNotEmpty
              ? ExpansionTile(
                  title: Text(
                    '${FindElement(a.tag, a.vr, '').tagText} ${a.keyword} · ${a.vr}',
                  ),
                  children: [
                    for (var i = 0; i < a.items.length; i++)
                      ExpansionTile(
                        title: Text('Item ${i + 1}'),
                        children: _attributes(a.items[i]),
                      ),
                  ],
                )
              : SelectableText(
                  '${FindElement(a.tag, a.vr, '').tagText} ${a.keyword} · ${a.vr}\n${a.decodeLimited
                      ? 'Decode limited · unsupported character set'
                      : a.values.isEmpty || a.text.isEmpty
                      ? 'Empty'
                      : widget.reveal
                      ? a.text
                      : '••••'}',
                ),
        ),
  ];
  bool _matches(QueryAttribute a) =>
      _search.isEmpty ||
      '${FindElement(a.tag, a.vr, '').tagText} ${a.keyword}'
          .toLowerCase()
          .contains(_search) ||
      a.items.any((i) => i.any(_matches));
}
