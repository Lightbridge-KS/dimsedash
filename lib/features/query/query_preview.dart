import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/foundation.dart';

enum QueryLevel { study, series, image }

enum PreviewScenario { complete, empty, partial, rejected }

enum IdentifierPurpose { match, returnKey }

enum QueryEditor { filters, advanced, resolved }

enum PreviewKey { patientId, patientName, accession, date, modality, bodyPart }

class PreviewEntry {
  const PreviewEntry({
    this.value = '',
    this.enabled = true,
    this.purpose = IdentifierPurpose.returnKey,
  });
  final String value;
  final bool enabled;
  final IdentifierPurpose purpose;
  PreviewEntry copy({
    String? value,
    bool? enabled,
    IdentifierPurpose? purpose,
  }) => PreviewEntry(
    value: value ?? this.value,
    enabled: enabled ?? this.enabled,
    purpose: purpose ?? this.purpose,
  );
}

/// UI-only editing intent. This is not a validated DICOM Identifier contract.
class QueryPreviewDraft {
  QueryPreviewDraft({
    this.level = QueryLevel.study,
    this.studyUid,
    this.seriesUid,
    this.parent,
    Map<PreviewKey, PreviewEntry> entries = const {},
  }) : entries = Map.unmodifiable(entries);
  final QueryLevel level;
  final String? studyUid, seriesUid;
  final PreviewMatch? parent;
  final Map<PreviewKey, PreviewEntry> entries;
  PreviewEntry entry(PreviewKey key) => entries[key] ?? const PreviewEntry();
  QueryPreviewDraft withEntry(PreviewKey key, PreviewEntry value) =>
      QueryPreviewDraft(
        level: level,
        studyUid: studyUid,
        seriesUid: seriesUid,
        parent: parent,
        entries: {...entries, key: value},
      );
  List<PreviewKey> get keys => switch (level) {
    QueryLevel.study => [
      PreviewKey.patientId,
      PreviewKey.patientName,
      PreviewKey.accession,
      PreviewKey.date,
      PreviewKey.modality,
    ],
    QueryLevel.series => [PreviewKey.modality, PreviewKey.bodyPart],
    QueryLevel.image => [],
  };
  String? get validation {
    if (level != QueryLevel.study && (studyUid == null || studyUid!.isEmpty)) {
      return 'A parent Study Instance UID is required.';
    }
    if (level == QueryLevel.image &&
        (seriesUid == null || seriesUid!.isEmpty)) {
      return 'A parent Series Instance UID is required.';
    }
    for (final key in keys) {
      final e = entry(key);
      if (!e.enabled || e.purpose == IdentifierPurpose.returnKey) continue;
      if (e.value.isEmpty) {
        return '${keyName(key, level)} needs a matching value. Choose Return or disable it.';
      }
      if (key == PreviewKey.date) {
        final parts = e.value.split('-');
        if (parts.length > 2 ||
            parts.every((p) => p.isEmpty) ||
            parts.any((p) => p.isNotEmpty && !_validDate(p))) {
          return 'Use valid dates (YYYY-MM-DD), or a DA date/range in Advanced.';
        }
        if (parts.length == 2 &&
            parts.every((p) => p.isNotEmpty) &&
            parts[0].compareTo(parts[1]) > 0) {
          return 'Study date From must not be later than Through.';
        }
      }
    }
    return null;
  }

  String get identifier {
    final lines = [
      '(0008,0052) CS QueryRetrieveLevel = ${level.name.toUpperCase()}',
    ];
    if (level != QueryLevel.study) {
      lines.add('(0020,000D) UI StudyInstanceUID = ${studyUid ?? '<missing>'}');
    }
    if (level == QueryLevel.image) {
      lines.add(
        '(0020,000E) UI SeriesInstanceUID = ${seriesUid ?? '<missing>'}',
      );
    }
    for (final key in keys) {
      final e = entry(key);
      if (e.enabled) {
        lines.add(
          '${keyTag(key, level)} ${keyVr(key)} ${keyName(key, level)} = ${e.purpose == IdentifierPurpose.returnKey ? '<empty · return key>' : e.value}',
        );
      }
    }
    lines.add(switch (level) {
      QueryLevel.study => '(0020,000D) UI StudyInstanceUID = <empty · return key>\n(0008,1030) LO StudyDescription = <empty · return key>\n(0020,1206) IS NumberOfStudyRelatedSeries = <empty · return key>',
      QueryLevel.series => '(0020,000E) UI SeriesInstanceUID = <empty · return key>\n(0008,103E) LO SeriesDescription = <empty · return key>',
      QueryLevel.image => '(0008,0018) UI SOPInstanceUID = <empty · return key>\n(0020,0013) IS InstanceNumber = <empty · return key>',
    });
    return lines.join('\n');
  }

  static bool _validDate(String s) {
    if (!RegExp(r'^\d{8}$').hasMatch(s)) return false;
    final y = int.parse(s.substring(0, 4)),
        m = int.parse(s.substring(4, 6)),
        d = int.parse(s.substring(6));
    final date = DateTime(y, m, d);
    return y > 0 && date.year == y && date.month == m && date.day == d;
  }
}

String keyName(PreviewKey key, QueryLevel level) => switch (key) {
  PreviewKey.patientId => 'PatientID',
  PreviewKey.patientName => 'PatientName',
  PreviewKey.accession => 'AccessionNumber',
  PreviewKey.date => 'StudyDate',
  PreviewKey.modality =>
    level == QueryLevel.study ? 'ModalitiesInStudy' : 'Modality',
  PreviewKey.bodyPart => 'BodyPartExamined',
};
String keyTag(PreviewKey key, QueryLevel level) => switch (key) {
  PreviewKey.patientId => '(0010,0020)',
  PreviewKey.patientName => '(0010,0010)',
  PreviewKey.accession => '(0008,0050)',
  PreviewKey.date => '(0008,0020)',
  PreviewKey.modality =>
    level == QueryLevel.study ? '(0008,0061)' : '(0008,0060)',
  PreviewKey.bodyPart => '(0018,0015)',
};
String keyVr(PreviewKey key) => switch (key) {
  PreviewKey.patientId => 'LO',
  PreviewKey.patientName => 'PN',
  PreviewKey.accession => 'SH',
  PreviewKey.date => 'DA',
  PreviewKey.modality || PreviewKey.bodyPart => 'CS',
};

class PreviewMatch {
  const PreviewMatch({
    required this.description,
    required this.patientId,
    required this.patientName,
    required this.accession,
    required this.date,
    required this.modality,
    this.studyUid,
    this.seriesUid,
    this.sopUid,
    this.seriesCount,
    this.bodyPart,
  });
  final String description, patientId, patientName, accession, date, modality;
  final String? studyUid, seriesUid, sopUid, bodyPart;
  final int? seriesCount;
  bool canTarget(QueryLevel level) =>
      studyUid?.isNotEmpty == true &&
      (level == QueryLevel.study || seriesUid?.isNotEmpty == true) &&
      (level != QueryLevel.image || sopUid?.isNotEmpty == true);
  String targetIdentifier(QueryLevel level) =>
      'QueryRetrieveLevel = ${level.name.toUpperCase()}\nStudyInstanceUID = $studyUid${level != QueryLevel.study ? '\nSeriesInstanceUID = $seriesUid' : ''}${level == QueryLevel.image ? '\nSOPInstanceUID = $sopUid' : ''}';
}

class PreviewRequest {
  const PreviewRequest({
    required this.node,
    required this.client,
    required this.draft,
  });
  final PacsNode node;
  final ClientSettings client;
  final QueryPreviewDraft draft;
  bool settingsDiffer(AppConfiguration config) =>
      config.node?.id != node.id ||
      config.node?.revision != node.revision ||
      config.client.callingAe != client.callingAe ||
      client.timeouts.values.entries.any(
        (e) => config.client.timeouts.values[e.key] != e.value,
      );
}

class PreviewResultContext {
  PreviewResultContext({
    required this.request,
    required this.scenario,
    required this.sequence,
    required List<PreviewMatch> rows,
  }) : rows = List.unmodifiable(rows);
  final PreviewRequest request;
  final PreviewScenario scenario;
  final int sequence;
  final List<PreviewMatch> rows;
  String get status => switch (scenario) {
    PreviewScenario.complete => 'Complete · final 0x0000 · synthetic',
    PreviewScenario.empty => 'No matches · final 0x0000 · synthetic',
    PreviewScenario.partial => 'Partial · local result limit · synthetic',
    PreviewScenario.rejected =>
      'Association rejected · result 1 / source 1 / reason 7 · synthetic',
  };
}

class _LevelContext {
  _LevelContext(this.draft, this.result);
  final QueryPreviewDraft draft;
  final PreviewResultContext? result;
}

/// One shell-owned, bounded preview session. No I/O or production run ownership.
class QueryPreviewController extends ChangeNotifier {
  QueryPreviewController(this.nodeId);
  final String nodeId;
  QueryPreviewDraft _draft = QueryPreviewDraft();
  QueryPreviewDraft get draft => _draft;
  PreviewResultContext? _result;
  PreviewResultContext? get result => _result;
  PreviewMatch? _selected;
  PreviewMatch? get selected => _selected;
  QueryEditor editor = QueryEditor.filters;
  PreviewScenario scenario = PreviewScenario.complete;
  bool collapsed = false;
  bool dateEditedInAdvanced = false;
  double scrollOffset = 0;
  int formRevision = 0, _sequence = 0;
  final _parents = <QueryLevel, _LevelContext>{};

  void edit(PreviewKey key, String value) {
    if (key == PreviewKey.date) dateEditedInAdvanced = false;
    _draft = _draft.withEntry(
      key,
      PreviewEntry(
        value: value,
        purpose: value.isEmpty
            ? IdentifierPurpose.returnKey
            : IdentifierPurpose.match,
      ),
    );
    notifyListeners();
  }

  void advanced(
    PreviewKey key, {
    String? value,
    bool? enabled,
    IdentifierPurpose? purpose,
  }) {
    if (key == PreviewKey.date) dateEditedInAdvanced = true;
    _draft = _draft.withEntry(
      key,
      _draft.entry(key).copy(value: value, enabled: enabled, purpose: purpose),
    );
    notifyListeners();
  }

  void setEditor(QueryEditor value) {
    editor = value;
    formRevision++;
    notifyListeners();
  }

  void setCollapsed(bool value) {
    collapsed = value;
    formRevision++;
    notifyListeners();
  }

  void setScenario(PreviewScenario value) {
    scenario = value;
    notifyListeners();
  }

  String? run(AppConfiguration config, {required bool echoActive}) {
    if (echoActive) {
      return 'Echo is active. Wait for resource cleanup before running a preview.';
    }
    if (config.node?.id != nodeId) {
      return 'The preview node is no longer selected.';
    }
    if (_draft.validation != null) return _draft.validation;
    final request = PreviewRequest(
      node: config.node!,
      client: config.client,
      draft: _draft,
    );
    final fixtures = _fixtures(_draft);
    _result = PreviewResultContext(
      request: request,
      scenario: scenario,
      sequence: ++_sequence,
      rows: switch (scenario) {
        PreviewScenario.empty || PreviewScenario.rejected => [],
        PreviewScenario.partial => fixtures.take(1).toList(),
        PreviewScenario.complete => fixtures,
      },
    );
    _selected = null;
    notifyListeners();
    return null;
  }

  void select(PreviewMatch row) {
    if (_result?.rows.contains(row) != true || !row.canTarget(_draft.level)) {
      return;
    }
    _selected = row;
    notifyListeners();
  }

  void openChild(PreviewMatch row) {
    if (_draft.level == QueryLevel.image ||
        _result?.rows.contains(row) != true ||
        !row.canTarget(_draft.level)) {
      return;
    }
    _parents[_draft.level] = _LevelContext(_draft, _result);
    final next = _draft.level == QueryLevel.study
        ? QueryLevel.series
        : QueryLevel.image;
    _parents.removeWhere((k, v) => k.index >= next.index);
    _draft = QueryPreviewDraft(
      level: next,
      parent: row,
      studyUid: row.studyUid,
      seriesUid: next == QueryLevel.image ? row.seriesUid : null,
      entries: {
        PreviewKey.modality: _draft.entry(PreviewKey.modality),
        PreviewKey.bodyPart: _draft.entry(PreviewKey.bodyPart),
      },
    );
    _result = null;
    _selected = null;
    collapsed = false;
    formRevision++;
    notifyListeners();
  }

  void backTo(QueryLevel level) {
    final parent = _parents[level];
    if (parent == null || level.index >= _draft.level.index) return;
    _draft = parent.draft;
    _result = parent.result;
    _selected = null;
    _parents.removeWhere((k, v) => k.index >= level.index);
    collapsed = false;
    formRevision++;
    notifyListeners();
  }

  bool get dirty =>
      _result != null && _result!.request.draft.identifier != _draft.identifier;

  static List<PreviewMatch> _fixtures(QueryPreviewDraft draft) => List.generate(
    draft.level == QueryLevel.study ? 3 : 2,
    (i) => PreviewMatch(
      description: switch (draft.level) {
        QueryLevel.study => [
          'CT chest without contrast',
          'CT abdomen and pelvis',
          'CT chest with contrast',
        ][i],
        QueryLevel.series =>
          'Series ${i + 1} · ${i == 0 ? 'axial' : 'reformatted'}',
        QueryLevel.image => 'Instance ${i + 1}',
      },
      patientId: draft.level == QueryLevel.study
          ? 'SYNTH-${101 + i}'
          : 'SYNTH-${draft.studyUid!.split('.').last}',
      patientName: draft.level == QueryLevel.study
          ? ['DEMO^ALPHA', 'DEMO^BETA', 'DEMO^GAMMA'][i]
          : draft.parent!.patientName,
      accession: draft.parent?.accession ?? 'DEMO-${1001 + i}',
      date: draft.parent?.date ?? '2026-10-${21 - i * 3}',
      modality: 'CT',
      seriesCount: i == 2 ? null : i + 3,
      studyUid: draft.studyUid ?? '2.25.${101 + i}',
      seriesUid: draft.level == QueryLevel.study
          ? null
          : draft.seriesUid ?? '${draft.studyUid}.${i + 1}',
      sopUid: draft.level == QueryLevel.image
          ? '${draft.seriesUid}.${i + 1}'
          : null,
      bodyPart: draft.level == QueryLevel.series ? 'CHEST' : null,
    ),
  );
}
