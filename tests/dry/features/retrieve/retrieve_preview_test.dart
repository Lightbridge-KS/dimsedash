import 'dart:math';

import 'package:flutter/foundation.dart' as flutter;
import 'package:dimsedash/features/retrieve/retrieve_preview.dart';
import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter_test/flutter_test.dart';

const node = PacsNode(
  id: 'n',
  label: 'Example',
  calledAe: 'PACS_AET',
  host: '192.0.2.1',
  port: 104,
);
const config = AppConfiguration(nodes: [node], selectedNodeId: 'n');
RetrieveSeed seed([
  RetrieveScope scope = RetrieveScope.study,
  String source = 'query-1',
]) => RetrieveSeed(
  sourceId: source,
  node: node,
  client: config.client,
  scope: scope,
  description: 'Synthetic source',
  uids: {
    'StudyInstanceUID': '1.2.3',
    if (scope != RetrieveScope.study) 'SeriesInstanceUID': '1.2.3.4',
    if (scope == RetrieveScope.image) 'SOPInstanceUID': '1.2.3.4.5',
  },
);
void main() {
  test('required hierarchy, scoped keys, immutable UID editing and reset', () {
    final c = RetrievePreviewController('n');
    addTearDown(c.dispose);
    expect(
      c.open(
        RetrieveSeed(
          sourceId: 'bad',
          node: node,
          client: config.client,
          scope: RetrieveScope.image,
          description: '',
          uids: {'StudyInstanceUID': '1.2'},
        ),
      ),
      isFalse,
    );
    expect(c.open(seed(RetrieveScope.image)), isTrue);
    final original = c.draft;
    expect(() => original.uids['SOPInstanceUID'] = '2', throwsUnsupportedError);
    c.editUid('PatientName', 'ignored');
    expect(c.draft.identifier, isNot(contains('PatientName')));
    for (final invalid in [
      '',
      '1..2',
      '01.2',
      '1.2.',
      'a.2',
      List.filled(65, '1').join(),
    ]) {
      c.editUid('SOPInstanceUID', invalid);
      expect(c.draft.validation, isNotNull, reason: invalid);
    }
    c.editUid('SOPInstanceUID', '9.8.7');
    expect(c.draft.validation, isNull);
    expect(c.draft.edited, isTrue);
    expect(original.uids['SOPInstanceUID'], '1.2.3.4.5');
    c.resetIdentifier();
    expect(c.draft.edited, isFalse);
  });
  test('same source preserves draft, new source resets defaults without evicting latest', () {
    final c = RetrievePreviewController('n')..open(seed());
    addTearDown(c.dispose);
    expect(c.blocked(config, echoActive: false), contains('folder'));
    c.chooseFolder(true);
    c.method(RetrieveMethod.move);
    expect(c.blocked(config, echoActive: false), contains('receiver'));
    c.previewReceiver(config);
    expect(c.showSample(config, echoActive: false), isNull);
    final latest = c.latest;
    c.open(seed());
    expect(c.draft.method, RetrieveMethod.move);
    c.open(seed(RetrieveScope.series, 'query-2'));
    expect(c.draft.method, RetrieveMethod.get);
    expect(c.draft.folder, isNull);
    expect(c.latest, same(latest));
  });
  test('configuration changes invalidate receiver readiness and preserve frozen evidence', () {
    final c = RetrievePreviewController('n')
      ..open(seed())
      ..chooseFolder(true)
      ..method(RetrieveMethod.move)
      ..previewReceiver(config);
    addTearDown(c.dispose);
    c.showSample(config, echoActive: false);
    final frozen = c.latest!;
    const changed = AppConfiguration(
      nodes: [node],
      selectedNodeId: 'n',
      client: ClientSettings(callingAe: 'CHANGED', listenPort: 11113),
    );
    c.syncConfiguration(changed);
    expect(c.receiverReady(changed), isFalse);
    c.syncConfiguration(config);
    expect(
      c.receiverReady(config),
      isFalse,
      reason: 'Reverting settings must not resurrect readiness',
    );
    expect(frozen.request.differs(changed), isTrue);
    expect(frozen.request.client.callingAe, 'DIMSE_DASH');
    c.editUid('StudyInstanceUID', '4.5.6');
    expect(frozen.request.draft.uids['StudyInstanceUID'], '1.2.3');
  });
  test('every scenario is bounded and scope appropriate, peer facts separate from saves', () {
    for (final scope in RetrieveScope.values) {
      final c = RetrievePreviewController('n')
        ..open(seed(scope))
        ..chooseFolder(true)
        ..method(RetrieveMethod.move)
        ..previewReceiver(config);
      for (final scenario in RetrieveScenario.values) {
        c.setScenario(scenario);
        expect(c.showSample(config, echoActive: false), isNull);
        final sample = c.latest!;
        expect(
          sample.received,
          lessThanOrEqualTo(scope == RetrieveScope.image ? 1 : 3),
        );
        expect(sample.receipts.length, sample.received);
        expect(sample.saved + sample.saveFailed, sample.received);
        if (scenario == RetrieveScenario.receiving) {
          expect(sample.completed, 0);
          expect(sample.saved, 1, reason: 'Saved is not acknowledged');
        }
        if (scenario == RetrieveScenario.destinationUnknown) {
          expect(sample.status, contains('0xA801'));
          expect(sample.completed, isNull);
        }
      }
      c.method(RetrieveMethod.get);
      c.setScenario(RetrieveScenario.destinationUnknown);
      expect(c.scenario, RetrieveScenario.complete);
      c.dispose();
    }
  });
  test('busy guard, stale IDs, transitions and explicit new execution', () {
    final c = RetrievePreviewController('n')
      ..open(seed())
      ..chooseFolder(true)
      ..setScenario(RetrieveScenario.receiving);
    addTearDown(c.dispose);
    expect(c.showSample(config, echoActive: true), contains('Echo'));
    expect(c.latest, isNull);
    c.showSample(config, echoActive: false);
    final first = c.latest!;
    expect(
      c.transition(first.id, RetrieveScenario.complete, echoActive: true),
      isFalse,
    );
    expect(
      c.transition('obsolete', RetrieveScenario.complete, echoActive: false),
      isFalse,
    );
    expect(
      c.transition(
        first.id,
        RetrieveScenario.cancelRequested,
        echoActive: false,
      ),
      isTrue,
    );
    expect(c.latest!.status, contains('confirmation not observed'));
    expect(
      c.transition(first.id, RetrieveScenario.complete, echoActive: false),
      isTrue,
    );
    expect(c.latest!.request, same(first.request));
    c.showSample(config, echoActive: false);
    expect(c.latest!.id, isNot(first.id));
    expect(
      c.transition(first.id, RetrieveScenario.complete, echoActive: false),
      isFalse,
    );
    expect(
      c.showSample(const AppConfiguration(), echoActive: false),
      contains('no longer selected'),
    );
  });
  test('UID map and timeout comparisons preserve entry equality', () {
    final random = Random(622);
    for (var i = 0; i < 250; i++) {
      final a = <String, String>{
        for (var j = 0; j < random.nextInt(5); j++)
          'UID$j': '2.25.${random.nextInt(5)}',
      };
      final b = i.isEven
          ? Map<String, String>.fromEntries(a.entries.toList().reversed)
          : {...a, 'UID${random.nextInt(5)}': '2.25.${random.nextInt(5)}'};
      final source = RetrieveSeed(
        sourceId: 'map-$i',
        node: node,
        client: config.client,
        scope: RetrieveScope.study,
        description: 'Synthetic',
        uids: a,
      );
      expect(
        RetrieveDraft(seed: source, uids: b).edited,
        !flutter.mapEquals(a, b),
      );
      final first = EchoTimeouts(
        connect: random.nextInt(100),
        association: random.nextInt(100),
      );
      final second = i.isEven
          ? first
          : EchoTimeouts(
              connect: first.connect + 1,
              association: first.association,
            );
      final client = ClientSettings(timeouts: first);
      final next = AppConfiguration(
        node: node,
        client: ClientSettings(timeouts: second),
      );
      expect(
        retrieveSettingsDiffer(node, client, next),
        !flutter.mapEquals(first.values, second.values),
      );
    }
  });
}
