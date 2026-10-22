import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bindings/configuration.dart';
import '../../bindings/echo.dart';
import 'retrieve_preview.dart';

class RetrievePreviewView extends ConsumerStatefulWidget {
  const RetrievePreviewView({
    super.key,
    required this.controller,
    required this.header,
    required this.onSample,
    required this.onReview,
    this.sampleId,
  });
  final RetrievePreviewController controller;
  final Widget header;
  final String? sampleId;
  final ValueChanged<String> onSample;
  final VoidCallback onReview;
  @override
  ConsumerState<RetrievePreviewView> createState() =>
      _RetrievePreviewViewState();
}

class _RetrievePreviewViewState extends ConsumerState<RetrievePreviewView> {
  late final ScrollController _scroll;
  RetrievePreviewController get c => widget.controller;
  bool get isRun => widget.sampleId != null;
  @override
  void initState() {
    super.initState();
    _scroll = ScrollController(
      initialScrollOffset: isRun ? c.runScroll : c.reviewScroll,
    );
    _scroll.addListener(() {
      if (isRun) {
        c.runScroll = _scroll.offset;
      } else {
        c.reviewScroll = _scroll.offset;
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(configurationProvider);
    final active = ref.watch(echoStateProvider.select((s) => s.active));
    final reveal = ref.watch(revealProvider);
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => SingleChildScrollView(
        key: const ValueKey('retrieve-scroll'),
        controller: _scroll,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            widget.header,
            const SizedBox(height: 16),
            Text(
              isRun ? 'Retrieve evidence · preview' : 'Review retrieve',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            _notice('UI preview · synthetic data · no network or files'),
            const Text(
              'Review → Receive → Inspect · fixed samples, not PACS matching or transfer simulation.',
            ),
            const SizedBox(height: 16),
            if (isRun)
              ..._run(config, active, reveal)
            else
              ..._review(config, active, reveal),
          ],
        ),
      ),
    );
  }

  List<Widget> _review(AppConfiguration config, bool active, bool reveal) {
    final d = c.draft;
    final blocked = c.blocked(config, echoActive: active);
    return [
      _panel('Selected target', [
        Text(d.seed.scopeLabel, style: Theme.of(context).textTheme.titleMedium),
        Text(
          d.edited
              ? 'Edited identifier · remote match unverified'
              : _value(d.seed.description, reveal),
        ),
        Text(
          d.edited
              ? 'Source description and counts no longer apply.'
              : 'Source: synthetic Query · ${d.seed.scope.name.toUpperCase()}',
        ),
        Text(
          d.seed.scope == RetrieveScope.image ? 'Scope: one instance' : 'Instance count: Not returned · includes instances not displayed in Query',
        ),
        if (retrieveSettingsDiffer(d.seed.node, d.seed.client, config))
          _notice(
            'Connection settings changed since the source Query. The next sample uses the current settings shown above; existing evidence stays frozen.',
          ),
      ]),
      _panel('Retrieval method', [
        for (final method in RetrieveMethod.values)
          ListTile(
            contentPadding: EdgeInsets.zero,
            selected: d.method == method,
            leading: Icon(
              d.method == method
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
            ),
            title: Text(method.label),
            subtitle: Text(
              method == RetrieveMethod.get
                  ? 'Storage on the requesting association. No separate listener required.'
                  : 'Separate storage callback to the local destination AE.',
            ),
            onTap: () => c.method(method),
          ),
        const Text(
          'Method selection does not prove peer support. No automatic fallback.',
        ),
      ]),
      _panel('Receive destination · sample only', [
        Text(d.folder ?? 'No sample folder selected'),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton(
              onPressed: () => c.chooseFolder(true),
              child: const Text('Choose sample folder'),
            ),
            if (d.folder != null)
              TextButton(
                onPressed: () => c.chooseFolder(false),
                child: const Text('Clear sample folder'),
              ),
          ],
        ),
        const Text(
          'Fictional folder alias · no path access, permission checks or files.',
        ),
        if (d.method == RetrieveMethod.move) ...[
          const Divider(height: 24),
          Text('Move destination AE · ${config.client.callingAe}'),
          Text('Local listening port · ${config.client.listenPort}'),
          Text(
            c.receiverReady(config)
                ? 'Simulated receiver ready · no socket opened'
                : 'Simulated receiver stopped',
          ),
          OutlinedButton(
            onPressed: c.receiverReady(config)
                ? null
                : () => c.previewReceiver(config),
            child: const Text('Preview receiver started'),
          ),
          const Text(
            'Remote reachability unverified. The PACS owns destination AE/address/port registration. Local Settings do not update that registration.',
          ),
        ],
      ]),
      _disclosure('advanced', 'Advanced Identifier', [
        Text(
          'QueryRetrieveLevel = ${d.seed.scope.name.toUpperCase()} · locked',
        ),
        const Text(
          'Required UID values only · no Find predicates or arbitrary tag editing.',
        ),
        if (!reveal) const Text('Reveal values to edit UIDs.'),
        for (final key in d.seed.requiredKeys)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TextFormField(
              key: ValueKey('retrieve-$key-${c.formRevision}-$reveal'),
              initialValue: reveal ? d.uids[key] : 'Hidden',
              enabled: reveal,
              decoration: InputDecoration(labelText: '$key · UI'),
              onChanged: (value) => c.editUid(key, value),
            ),
          ),
        if (d.validation != null)
          Text(
            d.validation!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        TextButton(
          onPressed: d.edited ? c.resetIdentifier : null,
          child: const Text('Reset to selected target'),
        ),
      ]),
      _disclosure('resolved', 'Resolved request', [
        Text('${d.method.label} · Study Root · next sample request'),
        Text(
          'Source node ${config.node?.label} · revision ${config.node?.revision}',
        ),
        Text(
          'Calling AE ${config.client.callingAe} · ${d.folder ?? 'Folder not selected'}',
        ),
        if (d.method == RetrieveMethod.move)
          Text(
            'Move Destination (command parameter) = ${config.client.callingAe}',
          ),
        const Text('Dataset elements'),
        Text(_value(d.identifier, reveal)),
        const Text(
          'Connection settings and Move Destination are outside the dataset.',
        ),
      ]),
      _disclosure('controls', 'Preview controls', [
        const Text(
          'Fixed responses are independent of entered UIDs, sample folder and query criteria.',
        ),
        DropdownButtonFormField<RetrieveScenario>(
          key: ValueKey('retrieve-scenario-${d.method}-${c.scenario}'),
          initialValue: c.scenario,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Sample scenario'),
          items: [
            for (final s in RetrieveScenario.values.where(
              (s) => !s.moveOnly || d.method == RetrieveMethod.move,
            ))
              DropdownMenuItem(value: s, child: Text(s.label)),
          ],
          onChanged: (s) {
            if (s != null) c.setScenario(s);
          },
        ),
      ]),
      if (blocked != null) _notice(blocked),
      Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.icon(
          key: const ValueKey('show-retrieve-sample'),
          onPressed: blocked != null
              ? null
              : () {
                  final error = c.showSample(
                    ref.read(configurationProvider),
                    echoActive: ref.read(echoStateProvider).active,
                  );
                  if (error == null) widget.onSample(c.latest!.id);
                },
          icon: const Icon(Icons.play_arrow),
          label: Text('Show ${d.method.label} sample run'),
        ),
      ),
    ];
  }

  List<Widget> _run(AppConfiguration config, bool active, bool reveal) {
    final sample = c.latest;
    if (sample == null || sample.id != widget.sampleId) {
      return [
        const Text('This sample detail is no longer retained.'),
        TextButton(
          onPressed: widget.onReview,
          child: const Text('Review new retrieve'),
        ),
      ];
    }
    final r = sample.request;
    String count(int? n) => n?.toString() ?? 'Not reported';
    return [
      _panel('Frozen sample request', [
        Text('${r.draft.method.label} · ${r.draft.seed.scopeLabel}'),
        Text(
          r.draft.edited
              ? 'Edited identifier · remote match unverified'
              : _value(r.draft.seed.description, reveal),
        ),
        Text(
          'Frozen node ${r.node.label} · ${r.node.calledAe} · ${r.node.host}:${r.node.port}',
        ),
        Text(
          'Node revision ${r.node.revision} · Calling AE ${r.client.callingAe}',
        ),
        Text(
          'Timeouts · connect ${r.client.timeouts.connect}s · association ${r.client.timeouts.association}s · DIMSE ${r.client.timeouts.dimse}s · idle ${r.client.timeouts.idle}s',
        ),
        Text('Sample destination · ${r.draft.folder}'),
        if (r.draft.method == RetrieveMethod.move)
          Text(
            'Move Destination ${r.client.callingAe} · port ${r.client.listenPort}',
          ),
        if (r.differs(config))
          _notice(
            'Current connection settings differ from this frozen sample.',
          ),
        _disclosure('executed', 'Executed Identifier · synthetic', [
          Text(_value(r.draft.identifier, reveal)),
        ]),
      ]),
      _panel('Sample outcome', [
        Text(sample.status),
        const Text(
          'All counts, statuses and observations below are synthetic.',
        ),
        if (sample.transitional) ...[
          const Text(
            'This is a static snapshot. Navigation does not advance it or own any operation.',
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed:
                    active ||
                        sample.scenario == RetrieveScenario.cancelRequested
                    ? null
                    : () => c.transition(
                        sample.id,
                        RetrieveScenario.cancelRequested,
                        echoActive: ref.read(echoStateProvider).active,
                      ),
                child: const Text('Preview cancel request'),
              ),
              OutlinedButton(
                onPressed: active
                    ? null
                    : () => c.transition(
                        sample.id,
                        RetrieveScenario.complete,
                        echoActive: ref.read(echoStateProvider).active,
                      ),
                child: const Text('Show completion snapshot'),
              ),
            ],
          ),
        ],
        if (active)
          _notice(
            'Echo is active. Sample transitions wait for cleanup; browsing remains available.',
          ),
      ]),
      _panel('Peer reported · synthetic', [
        Text(
          'Completed ${count(sample.completed)} · Failed ${count(sample.failed)} · Warning ${count(sample.warning)} · Remaining ${count(sample.remaining)}',
        ),
        const Text(
          'Missing counts are not zero. Query counts are not a transfer denominator.',
        ),
      ]),
      _panel('Local receipts / save results · synthetic', [
        Text(
          'Received ${sample.received} · Saved ${sample.saved} · Save failed ${sample.saveFailed}',
        ),
        const Text(
          'Saved does not prove successful acknowledgement or unique SOP count.',
        ),
        if (sample.noReceipts)
          const Text(
            'No linked receipts in this sample. No cause is established.',
          ),
        for (final receipt in sample.receipts)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sample delivery ${receipt.id} · ${receipt.saved ? 'Saved (synthetic)' : 'Save failed (synthetic)'}',
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => _inspect(receipt, thumbnail: false),
                      child: Text('Inspect headers ${receipt.id}'),
                    ),
                    TextButton(
                      onPressed: () => _inspect(receipt, thumbnail: true),
                      child: Text('Thumbnail ${receipt.id}'),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ]),
      if (r.draft.method == RetrieveMethod.move)
        _panel('Receiver-wide activity · synthetic', [
          const Text(
            'Unlinked deliveries: Not observed in this fixture. Excluded from run-linked totals.',
          ),
          const Text(
            'No callback does not establish a firewall failure. Suggested checks: destination registration and callback path.',
          ),
        ]),
      TextButton(
        onPressed: widget.onReview,
        child: const Text('Review new retrieve'),
      ),
    ];
  }

  Widget _disclosure(String key, String title, List<Widget> children) =>
      ExpansionTile(
        key: ValueKey(key),
        initiallyExpanded: c.expanded[key] ?? false,
        onExpansionChanged: (v) => c.expanded[key] = v,
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
  Widget _panel(String title, List<Widget> children) => Card.outlined(
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
  Widget _notice(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(
      text,
      style: TextStyle(color: Theme.of(context).colorScheme.primary),
    ),
  );
  String _value(String value, bool reveal) =>
      reveal ? value : 'Hidden · use Reveal values';

  Future<void> _inspect(SampleReceipt receipt, {required bool thumbnail}) =>
      showDialog<void>(
        context: context,
        builder: (context) =>
            _ReceiptDialog(receipt: receipt, thumbnail: thumbnail),
      );
}

class _ReceiptDialog extends ConsumerStatefulWidget {
  const _ReceiptDialog({required this.receipt, required this.thumbnail});
  final SampleReceipt receipt;
  final bool thumbnail;
  @override
  ConsumerState<_ReceiptDialog> createState() => _ReceiptDialogState();
}

class _ReceiptDialogState extends ConsumerState<_ReceiptDialog> {
  bool shown = false;
  @override
  Widget build(BuildContext context) {
    final reveal = ref.watch(revealProvider);
    final r = widget.receipt;
    return AlertDialog(
      title: Text(
        widget.thumbnail
            ? 'Thumbnail · placeholder'
            : 'Saved-object headers · synthetic',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Synthetic receipt only. No file exists or has been read.',
            ),
            if (!r.saved)
              const Text(
                'Save failed · no saved headers or thumbnail available.',
              )
            else if (!widget.thumbnail)
              Text(
                reveal
                    ? 'PatientName = SAMPLE^ONLY\nPatientID = SYNTHETIC\nDelivery = ${r.id}\nHeaders are fixed illustration values, not decoded DICOM.'
                    : 'Headers hidden · use session Reveal values',
              ),
            if (r.saved && widget.thumbnail) ...[
              if (r.unsupported)
                const Text(
                  'Unsupported preview · illustrative codec limitation',
                )
              else if (shown && reveal)
                const SizedBox(
                  height: 120,
                  width: 180,
                  child: Center(child: Icon(Icons.image_outlined, size: 64)),
                )
              else
                const Text('Thumbnail placeholder hidden'),
              if (!r.unsupported)
                TextButton(
                  onPressed: reveal
                      ? () => setState(() => shown = !shown)
                      : null,
                  child: Text(
                    shown ? 'Hide placeholder' : 'Reveal placeholder',
                  ),
                ),
              const Text(
                'No image pixels, decoding or diagnostic interpretation. Session Reveal and separate object reveal are required.',
              ),
            ],
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
  }
}
