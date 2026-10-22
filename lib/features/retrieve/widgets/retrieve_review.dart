import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';

import '../preview/retrieve_preview_controller.dart';
import '../preview/retrieve_preview_model.dart';
import 'retrieve_display.dart';

/// Edits the next preview request without owning execution or navigation.
class RetrieveReview extends StatelessWidget {
  const RetrieveReview({
    super.key,
    required this.controller,
    required this.config,
    required this.active,
    required this.reveal,
    required this.onShowSample,
  });
  final RetrievePreviewController controller;
  final AppConfiguration config;
  final bool active, reveal;
  final VoidCallback onShowSample;
  RetrievePreviewController get c => controller;

  @override
  Widget build(BuildContext context) {
    final d = c.draft;
    final blocked = c.blocked(config, echoActive: active);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        retrievePanel(context, 'Selected target', [
          Text(
            d.seed.scopeLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            d.edited
                ? 'Edited identifier · remote match unverified'
                : retrieveValue(d.seed.description, reveal),
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
            retrieveNotice(
              context,
              'Connection settings changed since the source Query. The next sample uses the current settings shown above; existing evidence stays frozen.',
            ),
        ]),
        retrievePanel(context, 'Retrieval method', [
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
        retrievePanel(context, 'Receive destination · sample only', [
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
        retrieveDisclosure(c.expanded, 'advanced', 'Advanced Identifier', [
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
        retrieveDisclosure(c.expanded, 'resolved', 'Resolved request', [
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
          Text(retrieveValue(d.identifier, reveal)),
          const Text(
            'Connection settings and Move Destination are outside the dataset.',
          ),
        ]),
        retrieveDisclosure(c.expanded, 'controls', 'Preview controls', [
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
        if (blocked != null) retrieveNotice(context, blocked),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            key: const ValueKey('show-retrieve-sample'),
            onPressed: blocked != null ? null : onShowSample,
            icon: const Icon(Icons.play_arrow),
            label: Text('Show ${d.method.label} sample run'),
          ),
        ),
      ],
    );
  }
}
