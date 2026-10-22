import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/foundation.dart';

import 'query_preview_model.dart';

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
