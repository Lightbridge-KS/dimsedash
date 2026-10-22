import 'package:dimsedash_core/dimsedash_core.dart';

enum RetrieveScope { study, series, image }

enum RetrieveMethod {
  get('C-GET'),
  move('C-MOVE');

  const RetrieveMethod(this.label);
  final String label;
}

enum RetrieveScenario {
  complete('Complete'),
  receiving('Receiving'),
  saveFailure('Local save failure'),
  cancelRequested('Cancel requested'),
  interrupted('Interrupted'),
  noCallback('No callback'),
  destinationUnknown('Move destination unknown');

  const RetrieveScenario(this.label);
  final String label;
  bool get moveOnly => this == noCallback || this == destinationUnknown;
}

/// Presentation handoff, constructed by the shell from one frozen Query row.
class RetrieveSeed {
  RetrieveSeed({
    required this.sourceId,
    required this.node,
    required this.client,
    required this.scope,
    required this.description,
    required Map<String, String> uids,
  }) : uids = Map.unmodifiable(uids);
  final String sourceId;
  final PacsNode node;
  final ClientSettings client;
  final RetrieveScope scope;
  final String description;
  final Map<String, String> uids;
  String get scopeLabel => scope == RetrieveScope.image
      ? 'This instance only'
      : 'All instances in this ${scope.name}';
  List<String> get requiredKeys => [
    'StudyInstanceUID',
    if (scope != RetrieveScope.study) 'SeriesInstanceUID',
    if (scope == RetrieveScope.image) 'SOPInstanceUID',
  ];
  bool get complete =>
      requiredKeys.every((key) => uids[key]?.isNotEmpty == true);
}

class RetrieveDraft {
  RetrieveDraft({
    required this.seed,
    this.method = RetrieveMethod.get,
    this.folder,
    Map<String, String>? uids,
  }) : uids = Map.unmodifiable(uids ?? seed.uids);
  final RetrieveSeed seed;
  final RetrieveMethod method;
  final String? folder;
  final Map<String, String> uids;
  bool get edited => !_sameMapEntries(uids, seed.uids);
  String get identifier => [
    'QueryRetrieveLevel = ${seed.scope.name.toUpperCase()}',
    for (final key in seed.requiredKeys) '$key = ${uids[key] ?? ''}',
  ].join('\n');
  String? get validation {
    for (final key in seed.requiredKeys) {
      final value = uids[key] ?? '';
      if (value.isEmpty ||
          value.length > 64 ||
          !RegExp(r'^[0-9]+(\.[0-9]+)*$').hasMatch(value) ||
          value.split('.').any((p) => p.length > 1 && p.startsWith('0'))) {
        return '$key requires a UID of 1–64 digits/dots, nonempty components and no leading zeros.';
      }
    }
    return null;
  }

  RetrieveDraft copy({
    RetrieveMethod? method,
    String? folder,
    bool clearFolder = false,
    Map<String, String>? uids,
  }) => RetrieveDraft(
    seed: seed,
    method: method ?? this.method,
    folder: clearFolder ? null : folder ?? this.folder,
    uids: uids ?? this.uids,
  );
}

bool retrieveSettingsDiffer(
  PacsNode node,
  ClientSettings client,
  AppConfiguration config,
) =>
    node.id != config.node?.id ||
    node.revision != config.node?.revision ||
    client.callingAe != config.client.callingAe ||
    client.listenPort != config.client.listenPort ||
    !_sameMapEntries(client.timeouts.values, config.client.timeouts.values);

class RetrieveSnapshot {
  const RetrieveSnapshot({
    required this.draft,
    required this.node,
    required this.client,
  });
  final RetrieveDraft draft;
  final PacsNode node;
  final ClientSettings client;
  bool differs(AppConfiguration config) =>
      retrieveSettingsDiffer(node, client, config);
}

class SampleReceipt {
  const SampleReceipt(this.id, {this.saved = true, this.unsupported = false});
  final int id;
  final bool saved, unsupported;
}

/// Fixed synthetic facts, never inferred from the peer or the filesystem.
class RetrieveSample {
  const RetrieveSample({
    required this.id,
    required this.request,
    required this.scenario,
  });
  final String id;
  final RetrieveSnapshot request;
  final RetrieveScenario scenario;
  int get total => request.draft.seed.scope == RetrieveScope.image ? 1 : 3;
  bool get transitional =>
      scenario == RetrieveScenario.receiving ||
      scenario == RetrieveScenario.cancelRequested;
  bool get noReceipts =>
      scenario == RetrieveScenario.noCallback ||
      scenario == RetrieveScenario.destinationUnknown;
  int get received => noReceipts
      ? 0
      : transitional || scenario == RetrieveScenario.interrupted
      ? 1
      : total;
  int get saveFailed => scenario == RetrieveScenario.saveFailure ? 1 : 0;
  int get saved => received - saveFailed;
  int? get completed => noReceipts || scenario == RetrieveScenario.interrupted
      ? null
      : transitional
      ? 0
      : total - saveFailed;
  int? get failed => completed == null ? null : saveFailed;
  int? get warning => completed == null ? null : 0;
  int? get remaining => transitional ? total : null;
  String get status => switch (scenario) {
    RetrieveScenario.complete => 'Synthetic final status 0x0000 · Success',
    RetrieveScenario.receiving => 'Synthetic pending status 0xFF00 · Receiving',
    RetrieveScenario.saveFailure =>
      'Synthetic final status 0xB000 · Sub-operation failure',
    RetrieveScenario.cancelRequested =>
      'Synthetic cancel intent · final confirmation not observed',
    RetrieveScenario.interrupted =>
      'Synthetic interruption · final status not observed',
    RetrieveScenario.noCallback => 'Synthetic observation window ended · no callback observed; final status unknown',
    RetrieveScenario.destinationUnknown =>
      'Synthetic final status 0xA801 · Move Destination unknown',
  };
  List<SampleReceipt> get receipts => List.unmodifiable([
    for (var i = 1; i <= received; i++)
      SampleReceipt(
        i,
        saved: !(saveFailed > 0 && i == received),
        unsupported: i == 2,
      ),
  ]);
}

bool _sameMapEntries<K, V>(Map<K, V> a, Map<K, V> b) {
  if (a.length != b.length) return false;
  if (identical(a, b)) return true;
  for (final key in a.keys) {
    if (!b.containsKey(key) || b[key] != a[key]) return false;
  }
  return true;
}
