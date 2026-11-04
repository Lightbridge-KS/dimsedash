import 'dart:async';

import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bindings/configuration.dart';
import '../../bindings/echo.dart';
import 'find_composer.dart';
import 'find_evidence.dart';
import 'find_inspection.dart';
import 'query_session.dart';

export 'find_evidence.dart' show FindRunView;

class FindView extends ConsumerStatefulWidget {
  const FindView({
    super.key,
    required this.session,
    required this.header,
    required this.onRetrieve,
    required this.retrieveFocus,
    this.restoreRetrieveFocus = false,
  });
  final QuerySession session;
  final Widget header;
  final ValueChanged<QuerySelection> onRetrieve;
  final FocusNode retrieveFocus;
  final bool restoreRetrieveFocus;
  @override
  ConsumerState<FindView> createState() => _FindViewState();
}

class _FindViewState extends ConsumerState<FindView> {
  late final _scroll = ScrollController(
    initialScrollOffset: widget.session.scrollOffset,
  );
  Timer? _clock;
  @override
  void initState() {
    super.initState();
    _scroll.addListener(() => widget.session.scrollOffset = _scroll.offset);
    // Presentation clock only. It never owns or delays networking.
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && (widget.session.runner?.state.active ?? false)) {
        setState(() {});
      }
    });
    if (widget.restoreRetrieveFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.retrieveFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _clock?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(configurationProvider),
        state = ref.watch(echoStateProvider);
    final reveal = ref.watch(revealProvider);
    return ListenableBuilder(
      listenable: widget.session,
      builder: (context, _) {
        final c = widget.session;
        c.syncConfiguration(config);
        final result = c.result;
        final activeHere = result?.active ?? false;
        final elapsed = result != null && result.runId == state.summary?.id
            ? DateTime.now().difference(state.summary!.started).inSeconds
            : null;
        return SingleChildScrollView(
          controller: _scroll,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              widget.header,
              const Text(
                'Query · live C-FIND',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Run query sends the resolved Identifier to this node. Results stay in this session; history excludes datasets and matching values.',
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (final level in c.ancestors)
                    TextButton(
                      onPressed: () => c.backTo(level),
                      child: Text(level.name.toUpperCase()),
                    ),
                  Chip(label: Text(c.draft.level.name.toUpperCase())),
                ],
              ),
              if (c.parent != null)
                const Text(
                  'Parent UIDs and query provenance are retained. Child results load only after Run query.',
                ),
              FindComposer(session: c, reveal: reveal),
              const SizedBox(height: 16),
              SizedBox(
                width: 220,
                child: FindField(
                  label: 'Retained row limit · 1–10,000',
                  value: c.draft.rowLimit.toString(),
                  onChanged: c.setLimit,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: c.busy ? null : () => c.run(config),
                    icon: const Icon(Icons.search),
                    label: const Text('Run query'),
                  ),
                  if (activeHere)
                    OutlinedButton(
                      onPressed: () {
                        if (c.runner?.state.summary?.id == result!.runId) {
                          c.runner?.stop();
                        }
                      },
                      child: const Text('Cancel query'),
                    ),
                  if (activeHere && elapsed != null)
                    Text('Elapsed ${elapsed}s'),
                  if (state.active && !activeHere)
                    const Text(
                      'Another outbound operation is active, including cleanup.',
                    ),
                ],
              ),
              if (c.error ?? c.dateError ?? c.draft.validation
                  case final String message)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (!state.historyAvailable)
                const Text(
                  'History unavailable. Further starts require storage recovery.',
                ),
              if (result == null)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No query has run at this level. Enter optional criteria, review the Identifier, then Run query.',
                  ),
                )
              else ...[
                const SizedBox(height: 20),
                Text(
                  findResultLabel(result),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Received ${result.received} · retained ${result.rows.length}. 50 rows per local page; no server pagination.',
                ),
                if (c.dirty || result.request.settingsDiffer(config))
                  const Text(
                    'Criteria or connection settings changed. Results and evidence retain the executed settings; edits apply to the next run.',
                  ),
                if (c.stale)
                  const Text(
                    'Connection identity changed. Selection and child continuation are disabled until this query is rerun.',
                  ),
                if (result.outcome?.optionalKeysUnsupported ?? false)
                  const Text(
                    'Optional-key warning (0xFF01): the peer may not have supported every requested key.',
                  ),
                if (result.rows.isEmpty && !result.active)
                  const Text('No retained matches.'),
                for (final row in result.rows.skip(c.page * 50).take(50))
                  _row(context, row, result, reveal),
                if (result.rows.length > 50)
                  Wrap(
                    spacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextButton(
                        onPressed: c.page > 0
                            ? () => c.setPage(c.page - 1)
                            : null,
                        child: const Text('Previous page'),
                      ),
                      Text(
                        'Page ${c.page + 1} of ${(result.rows.length / 50).ceil()}',
                      ),
                      TextButton(
                        onPressed: (c.page + 1) * 50 < result.rows.length
                            ? () => c.setPage(c.page + 1)
                            : null,
                        child: const Text('Next page'),
                      ),
                    ],
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonal(
                    focusNode: widget.retrieveFocus,
                    onPressed: c.selected == null || c.stale
                        ? null
                        : () => widget.onRetrieve(
                            QuerySelection(result, c.selected!),
                          ),
                    child: const Text('Review retrieve'),
                  ),
                ),
                ExpansionTile(
                  key: PageStorageKey('query-evidence-${result.runId}'),
                  title: const Text('Query evidence · frozen'),
                  children: [
                    FindEvidence(
                      result: result,
                      reveal: reveal,
                      state: state.summary?.id == result.runId ? state : null,
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _row(
    BuildContext context,
    QueryMatch row,
    QueryResultContext result,
    bool reveal,
  ) {
    final c = widget.session, level = result.request.identifier.level;
    final problem = c.actionProblem(row);
    final description = level == FindLevel.study
        ? 0x00081030
        : level == FindLevel.series
        ? 0x0008103E
        : 0x00200013;
    String value(int tag, {bool sensitive = false}) =>
        queryValue(row, tag, reveal, sensitive: sensitive);
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${row.ordinal}. ${value(description, sensitive: level != FindLevel.image)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (level == FindLevel.study) ...[
              Text(
                'Patient ${value(0x00100010, sensitive: true)} · ID ${value(0x00100020, sensitive: true)}',
              ),
              Text(
                'Study date ${value(0x00080020)} · modality ${value(0x00080061)} · accession ${value(0x00080050, sensitive: true)}',
              ),
              Text('Returned series count: ${value(0x00201206)}'),
            ],
            if (level == FindLevel.series)
              Text(
                'Modality ${value(0x00080060)} · body part ${value(0x00180015)} · returned instance count ${value(0x00201209)}',
              ),
            if (problem != null) Text(problem),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton(
                  onPressed: () =>
                      inspectQueryMatch(context, row, reveal, c.parent),
                  child: const Text('Inspect'),
                ),
                if (level != FindLevel.image)
                  TextButton(
                    onPressed: problem == null ? () => c.openChild(row) : null,
                    child: Text(
                      level == FindLevel.study
                          ? 'Open series'
                          : 'Open instances',
                    ),
                  ),
                TextButton.icon(
                  onPressed: problem == null ? () => c.select(row) : null,
                  icon: Icon(
                    identical(c.selected, row)
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  label: Text(
                    identical(c.selected, row) ? 'Selected' : 'Select',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
