import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bindings/configuration.dart';
import '../../bindings/echo.dart';
import 'preview/query_preview_controller.dart';
import 'preview/query_preview_model.dart';
import 'widgets/query_composer.dart';
import 'widgets/query_results.dart';
import 'widgets/query_evidence.dart';
import 'widgets/query_display.dart';

export 'preview/query_preview_model.dart' show QueryRetrieveSelection;

class QueryPreviewView extends ConsumerStatefulWidget {
  const QueryPreviewView({
    super.key,
    required this.controller,
    required this.header,
    required this.onRetrieve,
    this.retrieveFocus,
    this.restoreRetrieveFocus = false,
  });
  final QueryPreviewController controller;
  final Widget header;
  final ValueChanged<QueryRetrieveSelection> onRetrieve;
  final FocusNode? retrieveFocus;
  final bool restoreRetrieveFocus;
  @override
  ConsumerState<QueryPreviewView> createState() => _QueryPreviewViewState();
}

class _QueryPreviewViewState extends ConsumerState<QueryPreviewView> {
  late final ScrollController _scroll;
  String? _error;
  QueryPreviewController get c => widget.controller;
  @override
  void initState() {
    super.initState();
    _scroll = ScrollController(initialScrollOffset: c.scrollOffset);
    _scroll.addListener(() => c.scrollOffset = _scroll.offset);
    if (widget.restoreRetrieveFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.retrieveFocus?.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(configurationProvider);
    final echoActive = ref.watch(echoStateProvider.select((s) => s.active));
    final reveal = ref.watch(revealProvider);
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => SingleChildScrollView(
        key: const ValueKey('query-scroll'),
        controller: _scroll,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            widget.header,
            queryNotice(context, 'UI preview · synthetic data · no network'),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Fixed sample responses do not evaluate entered criteria or emulate PACS matching.',
              ),
            ),
            QueryComposer(
              controller: c,
              config: config,
              reveal: reveal,
              echoActive: echoActive,
              error: _error,
              onRun: () {
                final error = c.run(
                  ref.read(configurationProvider),
                  echoActive: ref.read(echoStateProvider).active,
                );
                setState(() => _error = error);
              },
            ),
            const SizedBox(height: 16),
            QueryResults(
              controller: c,
              reveal: reveal,
              onRetrieve: widget.onRetrieve,
              retrieveFocus: widget.retrieveFocus,
            ),
            if (c.result != null) ...[
              if (c.result!.request.settingsDiffer(config))
                queryNotice(
                  context,
                  'Current settings apply to the next preview. Results retain the frozen node revision, calling AE and timeouts.',
                ),
              QueryEvidence(result: c.result!, reveal: reveal),
            ],
            ExpansionTile(
              title: const Text('Preview controls'),
              children: [
                DropdownButtonFormField<PreviewScenario>(
                  initialValue: c.scenario,
                  decoration: const InputDecoration(
                    labelText: 'Synthetic response scenario',
                  ),
                  items: [
                    for (final scenario in PreviewScenario.values)
                      DropdownMenuItem(
                        value: scenario,
                        child: Text(switch (scenario) {
                          PreviewScenario.complete => 'Complete',
                          PreviewScenario.empty => 'No matches',
                          PreviewScenario.partial => 'Partial / local limit',
                          PreviewScenario.rejected => 'Association rejected',
                        }),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) c.setScenario(v);
                  },
                ),
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Only the selected scenario determines sample rows. Preview data is session-only and never enters run history.',
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
