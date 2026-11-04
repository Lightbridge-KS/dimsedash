import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';

import 'query_session.dart';

class FindComposer extends StatelessWidget {
  const FindComposer({super.key, required this.session, required this.reveal});
  final QuerySession session;
  final bool reveal;
  @override
  Widget build(BuildContext context) {
    final id = session.draft;
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${id.level.name.toUpperCase()} · Study Root Identifier',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () => session.setCollapsed(!session.collapsed),
                  child: Text(session.collapsed ? 'Edit criteria' : 'Collapse'),
                ),
              ],
            ),
            if (!session.collapsed) ...[
              Wrap(
                spacing: 8,
                children: [
                  for (final e in FindEditor.values)
                    ChoiceChip(
                      label: Text(switch (e) {
                        FindEditor.filters => 'Filters',
                        FindEditor.advanced => 'Advanced Identifier',
                        FindEditor.resolved => 'Resolved Identifier',
                      }),
                      selected: session.editor == e,
                      onSelected: (_) => session.setEditor(e),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (session.editor == FindEditor.filters) _filters(context),
              if (session.editor == FindEditor.advanced) ...[
                for (final e in id.elements.where((e) => e.required))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '${e.tagText} ${e.keyword} · ${e.vr} · Required / locked\n${e.value.isEmpty
                          ? 'Empty return key'
                          : e.vr == 'UI' && !reveal
                          ? '••••'
                          : e.value}',
                    ),
                  ),
                for (final key in id.keys) _advanced(context, key),
                const Text(
                  'S2B pending: arbitrary tags, private creators and sequence authoring. This editor supports the common keys shown above.',
                ),
              ],
              if (session.editor == FindEditor.resolved)
                IdentifierLines(identifier: id, reveal: reveal),
            ],
          ],
        ),
      ),
    );
  }

  Widget _filters(BuildContext context) {
    final id = session.draft;
    return LayoutBuilder(
      builder: (context, c) {
        final width = c.maxWidth >= 640 ? (c.maxWidth - 16) / 2 : c.maxWidth;
        Widget field(FindKey k, String label) => SizedBox(
          width: width,
          child: FindField(
            label: label,
            value: id.entry(k).value,
            obscure:
                !reveal &&
                {
                  FindKey.patientId,
                  FindKey.patientName,
                  FindKey.accession,
                }.contains(k),
            onChanged: (v) => session.edit(k, v),
            helper: entryState(id.entry(k)),
          ),
        );
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            if (id.level == FindLevel.study) ...[
              field(FindKey.patientId, 'Patient ID'),
              field(FindKey.patientName, 'Patient name'),
              field(FindKey.accession, 'Accession number'),
              for (final side in ['From', 'Through'])
                SizedBox(
                  width: width,
                  child: FindField(
                    label: 'Study date $side · inclusive',
                    value: session.dateText(side),
                    hint: 'YYYY-MM-DD',
                    onChanged: (v) => session.editDate(side, v),
                    helper: entryState(id.entry(FindKey.date)),
                  ),
                ),
              field(FindKey.modality, 'Modalities in study'),
              field(
                FindKey.bodyPart,
                'Body part (optional) · Next series query',
              ),
              SizedBox(
                width: c.maxWidth,
                child: Text(
                  id.entry(FindKey.bodyPart).value.isEmpty
                      ? 'Body part is unconstrained. It is not sent at STUDY level.'
                      : 'Pending next series query: body part is excluded from this STUDY Identifier.',
                ),
              ),
            ],
            if (id.level == FindLevel.series) ...[
              field(FindKey.modality, 'Series modality'),
              field(FindKey.bodyPart, 'Body part (optional)'),
            ],
            if (id.level == FindLevel.image)
              const Text(
                'The parent Study and Series Instance UIDs constrain this IMAGE query. Required identifiers are locked.',
              ),
            const Text(
              'Values are sent literally. Add wildcards explicitly when needed. Blank matching fields impose no restriction; enabled blank fields request return values. PACS support varies.',
            ),
          ],
        );
      },
    );
  }

  Widget _advanced(BuildContext context, FindKey key) {
    final id = session.draft, entry = session.draft.entry(key);
    final element = FindElement(findKeyTag(key, id.level), findKeyVr(key), '');
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${element.tagText} ${element.keyword} · ${element.vr}'),
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilterChip(
                label: const Text('Enabled'),
                selected: entry.enabled,
                onSelected: (v) => session.advanced(key, enabled: v),
              ),
              DropdownButton<FindPurpose>(
                value: entry.purpose,
                items: const [
                  DropdownMenuItem(
                    value: FindPurpose.match,
                    child: Text('Matching key'),
                  ),
                  DropdownMenuItem(
                    value: FindPurpose.returnKey,
                    child: Text('Empty return key'),
                  ),
                ],
                onChanged: (v) => session.advanced(key, purpose: v),
              ),
            ],
          ),
          FindField(
            label: '${element.keyword} value',
            value: entry.value,
            obscure:
                !reveal &&
                {
                  FindKey.patientId,
                  FindKey.patientName,
                  FindKey.accession,
                }.contains(key),
            onChanged: (v) => session.advanced(key, value: v),
            helper: entryState(entry),
          ),
        ],
      ),
    );
  }
}

String entryState(FindEntry e) => !e.enabled
    ? 'Disabled · omitted. Editing a friendly value re-enables it.'
    : e.purpose == FindPurpose.returnKey
    ? 'Empty return key · no matching restriction'
    : 'Matching key · literal value';

class IdentifierLines extends StatelessWidget {
  const IdentifierLines({
    super.key,
    required this.identifier,
    required this.reveal,
  });
  final FindIdentifier identifier;
  final bool reveal;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Dataset elements only. Destination and timeouts are connection settings.',
      ),
      for (final e in identifier.elements)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: SelectableText(
            '${e.tagText} ${e.keyword} · ${e.vr}\n${e.value.isEmpty
                ? '<empty return key>'
                : !reveal && e.tag != 0x00080052 && e.tag != 0x00080005
                ? '••••'
                : e.value}',
          ),
        ),
    ],
  );
}

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
  });
  final String label, value;
  final String? helper, hint;
  final bool obscure;
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
  Widget build(BuildContext context) => TextField(
    controller: _text,
    obscureText: widget.obscure,
    onChanged: widget.onChanged,
    decoration: InputDecoration(
      labelText: widget.label,
      helperText: widget.helper,
      helperMaxLines: 3,
      hintText: widget.hint,
      border: const OutlineInputBorder(),
    ),
  );
}
