import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bindings/configuration.dart';
import '../../bindings/echo.dart';
import 'preview/retrieve_preview_controller.dart';
import 'widgets/retrieve_review.dart';
import 'widgets/retrieve_evidence.dart';
import 'widgets/retrieve_display.dart';

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
            retrieveNotice(
              context,
              'UI preview · synthetic data · no network or files',
            ),
            const Text(
              'Review → Receive → Inspect · fixed samples, not PACS matching or transfer simulation.',
            ),
            const SizedBox(height: 16),
            if (isRun)
              ..._run(config, active, reveal)
            else
              RetrieveReview(
                controller: c,
                config: config,
                active: active,
                reveal: reveal,
                onShowSample: _showSample,
              ),
          ],
        ),
      ),
    );
  }

  void _showSample() {
    final error = c.showSample(
      ref.read(configurationProvider),
      echoActive: ref.read(echoStateProvider).active,
    );
    if (error == null) widget.onSample(c.latest!.id);
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
    return [
      RetrieveEvidence(
        sample: sample,
        config: config,
        active: active,
        reveal: reveal,
        expanded: c.expanded,
        onReview: widget.onReview,
        onTransition: (value) => c.transition(
          sample.id,
          value,
          echoActive: ref.read(echoStateProvider).active,
        ),
      ),
    ];
  }
}
