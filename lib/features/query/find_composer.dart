import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';

import 'query_session.dart';
import 'find_field.dart';
import 'find_identifier_editor.dart';
import '../../ui/workbench_tabs.dart';

class FindComposer extends StatelessWidget {
  const FindComposer({
    super.key,
    required this.session,
    required this.reveal,
    this.footer,
  });
  final QuerySession session;
  final bool reveal;
  final Widget? footer;
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Query criteria',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      'Study Root · ${findLevelLabel(id.level)} · C-FIND',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => session.setCollapsed(!session.collapsed),
                  child: Text(session.collapsed ? 'Edit criteria' : 'Collapse'),
                ),
              ],
            ),
            if (!session.collapsed) ...[
              const SizedBox(height: 12),
              WorkbenchTabs(
                secondary: true,
                labels: const [
                  'Filters',
                  'Advanced Identifier',
                  'Resolved Identifier',
                ],
                index: session.editor.index,
                onChanged: (i) => session.setEditor(FindEditor.values[i]),
              ),
              const SizedBox(height: 16),
              if (session.editor == FindEditor.filters) _filters(context),
              if (session.editor == FindEditor.advanced)
                FindIdentifierEditor(
                  identifier: id,
                  reveal: reveal,
                  dateError: session.friendlyDateError,
                  helpExpanded: session.identifierHelpExpanded,
                  onHelpChanged: session.setIdentifierHelpExpanded,
                  onEdit: session.advanced,
                ),
              if (session.editor == FindEditor.resolved)
                IdentifierLines(identifier: id, reveal: reveal),
            ],
            if (footer != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              footer!,
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
        final minimum = MediaQuery.textScalerOf(context).scale(320);
        final columns = c.maxWidth >= minimum * 3 + 32
            ? 3
            : c.maxWidth >= minimum * 2 + 16
            ? 2
            : 1;
        final width = (c.maxWidth - (columns - 1) * 16) / columns;
        String helper(FindKey key) {
          final entry = id.entry(key);
          final tag = FindElement(
            findKeyTag(key, id.level),
            findKeyVr(key),
            '',
          ).tagText;
          return '$tag${!entry.enabled
              ? ' · Omitted'
              : entry.purpose == FindPurpose.returnKey
              ? ' · Return only'
              : ''}';
        }

        Widget field(FindKey key, String label) => SizedBox(
          width: width,
          child: FindField(
            label: label,
            groupLabel: key == FindKey.modality || key == FindKey.bodyPart,
            value: id.entry(key).value,
            obscure:
                !reveal &&
                {
                  FindKey.patientId,
                  FindKey.patientName,
                  FindKey.accession,
                }.contains(key),
            onChanged: (v) => session.edit(key, v),
            helper: helper(key),
            suffix: key == FindKey.modality
                ? PopupMenuButton<String>(
                    tooltip: 'Choose modality',
                    icon: const Icon(Icons.arrow_drop_down),
                    onSelected: (value) => session.edit(key, value),
                    itemBuilder: (_) => [
                      for (final value in [
                        '',
                        'CT',
                        'MR',
                        'CR',
                        'DX',
                        'US',
                        'MG',
                        'NM',
                        'PT',
                        'XA',
                      ])
                        PopupMenuItem(
                          value: value,
                          child: Text(value.isEmpty ? 'Any' : value),
                        ),
                    ],
                  )
                : null,
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 24,
              children: [
                if (id.level == FindLevel.study) ...[
                  field(FindKey.patientId, 'Patient ID'),
                  field(FindKey.patientName, 'Patient name'),
                  field(FindKey.accession, 'Accession number'),
                  SizedBox(
                    width: width,
                    child: _dates(context, helper(FindKey.date)),
                  ),
                ],
                if (id.level != FindLevel.image) ...[
                  field(
                    FindKey.modality,
                    id.level == FindLevel.study
                        ? 'Modalities in study'
                        : 'Series modality',
                  ),
                  SizedBox(
                    width: width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        field(FindKey.bodyPart, 'Body part (optional)'),
                        if (id.level == FindLevel.study) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Next series query',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          Text(
                            'Not sent in this study query.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                if (id.level == FindLevel.image)
                  const Text(
                    'Parent Study and Series Instance UIDs constrain this instance query. Required identifiers are locked.',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              initiallyExpanded: session.matchingHelpExpanded,
              onExpansionChanged: session.setMatchingHelpExpanded,
              title: const Text('Matching help'),
              children: const [
                Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Values are sent literally. Add wildcards explicitly when needed. Filled matching keys are combined; there is no automatic OR. Blank fields impose no restriction; enabled empty return keys request values. Omitted keys are not sent. Editing a friendly value re-enables its key. PACS matching support varies. Results stay in this session; history excludes datasets and matching values.',
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _dates(BuildContext context, String helper) => CriteriaGroup(
    label: 'Study date period',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final stacked =
                c.maxWidth < MediaQuery.textScalerOf(context).scale(320);
            return Wrap(
              spacing: 8,
              runSpacing: 12,
              children: [
                for (final side in ['From', 'Through'])
                  SizedBox(
                    width: stacked ? c.maxWidth : (c.maxWidth - 8) / 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FindField(
                          label: side,
                          value: session.dateText(side),
                          hint: 'YYYY-MM-DD',
                          onChanged: (v) => session.editDate(side, v),
                          suffix: IconButton(
                            tooltip: 'Choose $side date',
                            icon: const Icon(Icons.calendar_today, size: 18),
                            onPressed: () => _pickDate(context, side),
                          ),
                        ),
                        if (session.dateText(side).isNotEmpty)
                          TextButton(
                            onPressed: () => session.editDate(side, ''),
                            child: Text('Clear $side date'),
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          '$helper · Inclusive dates',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (session.friendlyDateError case final String message)
          Text(
            message,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    ),
  );

  Future<void> _pickDate(BuildContext context, String side) async {
    final text = session.dateText(side);
    final parsed =
        RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text) &&
            validQueryDate(text.replaceAll('-', ''))
        ? DateTime.tryParse(text)
        : null;
    final selected = await showDatePicker(
      context: context,
      initialDate: parsed != null && parsed.year >= 1 ? parsed : DateTime.now(),
      firstDate: DateTime(1),
      lastDate: DateTime(9999, 12, 31),
      helpText: 'Study date · $side',
    );
    if (selected == null || !context.mounted) return;
    session.editDate(
      side,
      '${selected.year.toString().padLeft(4, '0')}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}',
    );
  }
}

String findLevelLabel(FindLevel level) => switch (level) {
  FindLevel.study => 'Studies',
  FindLevel.series => 'Series',
  FindLevel.image => 'Instances',
};

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
