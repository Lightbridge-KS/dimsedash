import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';

import 'find_field.dart';

typedef FindIdentifierEdit = void Function(
  FindKey key, {
  String? value,
  bool? enabled,
  FindPurpose? purpose,
});

/// Presentation of the canonical Identifier; this widget never dispatches work.
class FindIdentifierEditor extends StatefulWidget {
  const FindIdentifierEditor({
    super.key,
    required this.identifier,
    required this.reveal,
    required this.onEdit,
    required this.helpExpanded,
    required this.onHelpChanged,
    this.dateError,
  });
  final FindIdentifier identifier;
  final bool reveal, helpExpanded;
  final FindIdentifierEdit onEdit;
  final ValueChanged<bool> onHelpChanged;
  final String? dateError;

  @override
  State<FindIdentifierEditor> createState() => _FindIdentifierEditorState();
}

class _FindIdentifierEditorState extends State<FindIdentifierEditor> {
  // Global keys reparent these controls when the responsive layout changes.
  // Their controllers, caret and focus survive runtime-only rebuilds and resize.
  final _controls = {for (final key in FindKey.values) key: _RowControls()};

  @override
  void didUpdateWidget(FindIdentifierEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final key in FindKey.values) {
      final entry = widget.identifier.entry(key), controls = _controls[key]!;
      if (!entry.enabled &&
          (controls.value.hasFocus || controls.purpose.hasFocus)) {
        controls.include.requestFocus();
      } else if (entry.purpose != FindPurpose.match &&
          controls.value.hasFocus) {
        controls.purpose.requestFocus();
      }
    }
  }

  @override
  void dispose() {
    for (final controls in _controls.values) {
      controls.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.identifier;
    final editableTags = {for (final key in id.keys) findKeyTag(key, id.level)};
    final fixed = id.elements.where((e) => !editableTags.contains(e.tag));
    final required = fixed.where((e) => e.required && e.tag != 0x00080005);
    final automatic = fixed.where((e) => !e.required || e.tag == 0x00080005);
    return FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Shared with Filters. Changes apply to the next query.'),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            initiallyExpanded: widget.helpExpanded,
            onExpansionChanged: widget.onHelpChanged,
            title: const Text('Identifier editing help'),
            children: const [
              Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Match sends the literal value. Return only sends an empty value to request that attribute. Unchecked keys are omitted. Saved matching values remain in the draft; include the key and choose Match to edit them. Required and app-added fields cannot be changed here. PACS matching support varies.',
                ),
              ),
            ],
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final scale = MediaQuery.textScalerOf(context);
              final include = scale.scale(104), purpose = scale.scale(160);
              final wide =
                  constraints.maxWidth >=
                  include + purpose + scale.scale(240) + scale.scale(260);
              final rows = [
                for (final e in required) _fixed(context, e),
                for (final key in id.keys) _editable(context, key),
                for (final e in automatic) _fixed(context, e),
              ];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _layout(context, rows, wide, include, purpose),
                  if (id.level == FindLevel.study) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Next series query',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Text('Not included in this study Identifier'),
                    const SizedBox(height: 8),
                    _layout(
                      context,
                      [_editable(context, FindKey.bodyPart)],
                      wide,
                      include,
                      purpose,
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          const Text('Additional tags and sequences are not available yet.'),
        ],
      ),
    );
  }

  Widget _layout(
    BuildContext context,
    List<List<Widget>> rows,
    bool wide,
    double include,
    double purpose,
  ) {
    final colors = Theme.of(context).colorScheme;
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final cells in rows)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: colors.outlineVariant),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    cells[1],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(width: include, child: cells[0]),
                        SizedBox(width: purpose, child: cells[2]),
                      ],
                    ),
                    const SizedBox(height: 12),
                    cells[3],
                  ],
                ),
              ),
            ),
        ],
      );
    }
    return Table(
      columnWidths: {
        0: FixedColumnWidth(include),
        1: const FlexColumnWidth(240),
        2: FixedColumnWidth(purpose),
        3: const FlexColumnWidth(260),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      border: TableBorder(
        horizontalInside: BorderSide(color: colors.outlineVariant),
      ),
      children: [
        TableRow(
          decoration: BoxDecoration(color: colors.surfaceContainerLow),
          children: [
            for (final label in [
              'Include',
              'DICOM attribute',
              'Purpose',
              'Value',
            ])
              Padding(
                padding: const EdgeInsets.all(12),
                child: Semantics(
                  header: true,
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
          ],
        ),
        for (final cells in rows)
          TableRow(
            children: [
              for (final cell in cells)
                Padding(padding: const EdgeInsets.all(12), child: cell),
            ],
          ),
      ],
    );
  }

  List<Widget> _fixed(BuildContext context, FindElement e) {
    final automatic = e.tag == 0x00080005;
    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline, size: 18),
          Text(
            automatic
                ? 'Automatic'
                : e.required
                ? 'Required · locked'
                : 'Added by app',
          ),
        ],
      ),
      _attribute(context, e),
      Text(e.value.isEmpty ? 'Return only · locked' : 'Fixed value'),
      Text(
        e.value.isEmpty
            ? 'Empty value sent'
            : !widget.reveal && e.vr == 'UI'
            ? '••••'
            : e.value,
      ),
    ];
  }

  List<Widget> _editable(BuildContext context, FindKey key) {
    final id = widget.identifier,
        entry = id.entry(key),
        controls = _controls[key]!;
    final e = FindElement(findKeyTag(key, id.level), findKeyVr(key), '');
    final name = _friendly(e);
    final sensitive = {
      FindKey.patientId,
      FindKey.patientName,
      FindKey.accession,
    }.contains(key);
    final canEdit = entry.enabled && entry.purpose == FindPurpose.match;
    return [
      Align(
        alignment: Alignment.centerLeft,
        child: Checkbox(
          key: controls.includeKey,
          focusNode: controls.include,
          semanticLabel: 'Include $name',
          value: entry.enabled,
          onChanged: (value) {
            controls.include.requestFocus();
            widget.onEdit(key, enabled: value);
          },
        ),
      ),
      _attribute(context, e),
      DropdownButtonFormField<FindPurpose>(
        key: controls.purposeKey,
        focusNode: controls.purpose,
        initialValue: entry.purpose,
        isExpanded: true,
        iconSize: 18,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          labelText: '$name purpose',
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 12,
          ),
          border: const OutlineInputBorder(),
        ),
        items: const [
          DropdownMenuItem(value: FindPurpose.match, child: Text('Match')),
          DropdownMenuItem(
            value: FindPurpose.returnKey,
            child: Text('Return only'),
          ),
        ],
        onChanged: !entry.enabled
            ? null
            : (value) {
                controls.purpose.requestFocus();
                widget.onEdit(key, purpose: value);
              },
      ),
      if (canEdit)
        FindField(
          key: controls.valueKey,
          focusNode: controls.value,
          label: '$name value',
          value: entry.value,
          obscure: sensitive && !widget.reveal,
          onChanged: (value) => widget.onEdit(key, value: value),
          helper: key == FindKey.date
              ? 'DA: YYYYMMDD or YYYYMMDD-YYYYMMDD; either endpoint may be blank.'
              : null,
          error: entry.value.isEmpty
              ? 'Enter a matching value.'
              : key == FindKey.date
              ? widget.dateError
              : null,
        )
      else
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.enabled ? 'Empty value sent' : 'Not sent'),
            if (entry.value.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Saved draft value · not sent',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(sensitive && !widget.reveal ? '••••' : entry.value),
            ],
            if (key == FindKey.date && widget.dateError != null)
              Text(
                widget.dateError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
    ];
  }

  Widget _attribute(BuildContext context, FindElement e) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(_friendly(e), style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 4),
      Text(
        '${e.tagText} · ${e.vr}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      Text(e.keyword, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

String _friendly(FindElement e) => switch (e.tag) {
  0x00080052 => 'Query level',
  0x0020000D => 'Study Instance UID',
  0x0020000E => 'Series Instance UID',
  0x00080018 => 'SOP Instance UID',
  0x00100020 => 'Patient ID',
  0x00100010 => 'Patient name',
  0x00080050 => 'Accession number',
  0x00080020 => 'Study date',
  0x00080061 => 'Modalities in study',
  0x00080060 => 'Series modality',
  0x00180015 => 'Body part (optional)',
  0x00081030 => 'Study description',
  0x0008103E => 'Series description',
  0x00201206 => 'Number of series',
  0x00201209 => 'Number of instances',
  0x00200013 => 'Instance number',
  0x00080005 => 'Specific character set',
  _ => e.keyword,
};

class _RowControls {
  final includeKey = GlobalKey(),
      purposeKey = GlobalKey(),
      valueKey = GlobalKey();
  final include = FocusNode(), purpose = FocusNode(), value = FocusNode();
  void dispose() {
    include.dispose();
    purpose.dispose();
    value.dispose();
  }
}
