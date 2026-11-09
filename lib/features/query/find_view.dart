import 'dart:async';

import 'find_field.dart';
import 'find_results_panel.dart';

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
              Wrap(
                spacing: 8,
                children: [
                  for (final level in c.ancestors)
                    TextButton(
                      onPressed: () => c.backTo(level),
                      child: Text(findLevelLabel(level)),
                    ),
                  Chip(label: Text(findLevelLabel(c.draft.level))),
                ],
              ),
              if (c.parent != null)
                const Text(
                  'Parent UIDs and query provenance are retained. Child results load only after Run query.',
                ),
              FindComposer(
                session: c,
                reveal: reveal,
                footer: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Only Run query sends a request.'),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 16,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: 220,
                          child: FindField(
                            label: 'Keep up to',
                            value: c.draft.rowLimit.toString(),
                            helper: 'results · 1–10,000 retained locally',
                            onChanged: c.setLimit,
                          ),
                        ),
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
                                  if (c.runner?.state.summary?.id ==
                                      result!.runId) {
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
                      ],
                    ),
                  ],
                ),
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
              FindResultsPanel(
                level: c.draft.level,
                result: result,
                selected: c.selected,
                page: c.page,
                reveal: reveal,
                warnings: [
                  if (result != null &&
                      (c.dirty || result.request.settingsDiffer(config)))
                    'Criteria or connection settings changed. Results and evidence retain the executed settings; edits apply to the next run.',
                  if (c.stale) 'Connection identity changed. Selection and child continuation are disabled until this query is rerun.',
                  if (result?.outcome?.optionalKeysUnsupported ?? false) 'Optional-key warning (0xFF01): the peer may not have supported every requested key.',
                ],
                actionProblem: c.actionProblem,
                onSelect: c.select,
                onClear: c.clearSelection,
                onPage: c.setPage,
                onInspect: (row) =>
                    inspectQueryMatch(context, row, reveal, c.parent),
                onOpenChild: c.openChild,
                retrieveFocus: widget.retrieveFocus,
                onRetrieve: c.selected == null || c.stale || result == null
                    ? null
                    : () => widget.onRetrieve(
                        QuerySelection(result, c.selected!),
                      ),
              ),
              if (result != null) ...[
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
}
