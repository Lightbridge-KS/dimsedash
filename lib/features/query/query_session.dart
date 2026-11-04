import 'dart:async';

import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/foundation.dart';

enum FindEditor { filters, advanced, resolved }

final class QuerySelection {
  const QuerySelection(this.result, this.row);
  final QueryResultContext result;
  final QueryMatch row;
}

class _Context {
  _Context(this.draft, this.runId, this.parent);
  final FindIdentifier draft;
  final String? runId;
  final QueryMatch? parent;
}

/// Shell-owned presentation session. The runtime owns all network work and rows.
class QuerySession extends ChangeNotifier {
  QuerySession(this.nodeId, this.runner) {
    _subscription = runner?.changes.listen((_) {
      if (!_disposed) notifyListeners();
    });
  }
  final String nodeId;
  final OperationRunner? runner;
  StreamSubscription<EchoState>? _subscription;
  bool _disposed = false, starting = false;
  int _generation = 0;
  FindIdentifier draft = FindIdentifier();
  String? runId, error;
  QueryMatch? selected, parent;
  final _parents = <FindLevel, _Context>{};
  AppConfiguration? _configuration;
  FindEditor editor = FindEditor.filters;
  bool collapsed = false;
  double scrollOffset = 0;
  int page = 0;
  final dateInputs = <String, String>{};
  String? dateError;
  QueryResultContext? get result =>
      runId == null ? null : runner?.findResult(runId!);
  bool get stale =>
      result?.request.targetChanged(
        _configuration ?? const AppConfiguration(),
      ) ??
      false;
  bool get busy => starting || (runner?.state.active ?? false);
  bool get dirty =>
      result != null &&
      (result!.request.identifier.resolved != draft.resolved ||
          result!.request.identifier.rowLimit != draft.rowLimit);
  List<FindLevel> get ancestors =>
      _parents.keys.toList()..sort((a, b) => a.index.compareTo(b.index));

  void syncConfiguration(AppConfiguration config) {
    _configuration = config;
    if (stale) selected = null;
  }

  void edit(FindKey key, String value) {
    draft = draft.copy(
      key: key,
      value: FindEntry(
        value: value,
        purpose: value.isEmpty ? FindPurpose.returnKey : FindPurpose.match,
      ),
    );
    if (key == FindKey.date) {
      dateInputs.clear();
      dateError = null;
    }
    notifyListeners();
  }

  void advanced(
    FindKey key, {
    String? value,
    bool? enabled,
    FindPurpose? purpose,
  }) {
    draft = draft.copy(
      key: key,
      value: draft
          .entry(key)
          .copy(value: value, enabled: enabled, purpose: purpose),
    );
    if (key == FindKey.date) {
      dateInputs.clear();
      dateError = null;
    }
    notifyListeners();
  }

  void editDate(String side, String value) {
    final pair = draft.entry(FindKey.date).value.split('-');
    dateInputs.putIfAbsent('From', () => _friendlyDate(pair.first));
    dateInputs.putIfAbsent(
      'Through',
      () => pair.length == 2
          ? _friendlyDate(pair.last)
          : _friendlyDate(pair.first),
    );
    dateInputs[side] = value;
    final from = dateInputs['From']!, through = dateInputs['Through']!;
    bool valid(String s) =>
        s.isEmpty ||
        RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s) &&
            validQueryDate(s.replaceAll('-', ''));
    dateError = valid(from) && valid(through)
        ? null
        : 'Use a valid date in YYYY-MM-DD format.';
    if (dateError == null) {
      final a = from.replaceAll('-', ''), b = through.replaceAll('-', '');
      final value = a.isEmpty && b.isEmpty
          ? ''
          : a == b
          ? a
          : '$a-$b';
      draft = draft.copy(
        key: FindKey.date,
        value: FindEntry(
          value: value,
          purpose: value.isEmpty ? FindPurpose.returnKey : FindPurpose.match,
        ),
      );
    }
    notifyListeners();
  }

  String dateText(String side) {
    if (dateInputs.containsKey(side)) return dateInputs[side]!;
    final pair = draft.entry(FindKey.date).value.split('-');
    return _friendlyDate(side == 'From' ? pair.first : pair.last);
  }

  static String _friendlyDate(String s) => s.length == 8
      ? '${s.substring(0, 4)}-${s.substring(4, 6)}-${s.substring(6)}'
      : s;

  void setEditor(FindEditor value) {
    editor = value;
    notifyListeners();
  }

  void setCollapsed(bool value) {
    collapsed = value;
    notifyListeners();
  }

  void setLimit(String value) {
    draft = draft.copy(rowLimit: int.tryParse(value) ?? 0);
    notifyListeners();
  }

  void setPage(int value) {
    page = value;
    notifyListeners();
  }

  Future<void> run(AppConfiguration config) async {
    if (busy) return;
    error = dateError ?? draft.validation;
    if (error != null) {
      notifyListeners();
      return;
    }
    if (config.node?.id != nodeId || runner == null) {
      error = 'The selected node or operation runtime is unavailable.';
      notifyListeners();
      return;
    }
    if (draft.level != FindLevel.study && _parentStale(config)) {
      error = 'Connection identity changed. Return to STUDY and query again before continuing.';
      notifyListeners();
      return;
    }
    final generation = _generation;
    starting = true;
    notifyListeners();
    final started = await runner!.startFind(config.revision, draft);
    if (_disposed) return;
    starting = false;
    if (generation != _generation) {
      notifyListeners();
      return;
    }
    switch (started) {
      case Failure<RunHandle>(:final error):
        this.error = error.message;
      case Success<RunHandle>(:final value):
        runId = value.id;
        selected = null;
        page = 0;
        _retain();
    }
    notifyListeners();
  }

  bool _parentStale(AppConfiguration config) => _parents.values.any(
    (p) =>
        p.runId != null &&
        (runner?.findResult(p.runId!)?.request.targetChanged(config) ?? true),
  );
  String? actionProblem(QueryMatch row) => stale
      ? 'Connection identity changed. Run this query again.'
      : row.targetProblem(result!.request.identifier);
  void select(QueryMatch row) {
    if (result?.rows.contains(row) != true || actionProblem(row) != null) {
      return;
    }
    selected = row;
    notifyListeners();
  }

  void openChild(QueryMatch row) {
    if (draft.level == FindLevel.image ||
        result?.rows.contains(row) != true ||
        actionProblem(row) != null) {
      return;
    }
    _generation++;
    _parents[draft.level] = _Context(draft, runId, parent);
    final next = draft.level == FindLevel.study
        ? FindLevel.series
        : FindLevel.image;
    _parents.removeWhere((k, v) => k.index >= next.index);
    draft = FindIdentifier(
      level: next,
      studyUid: row.studyUid,
      seriesUid: next == FindLevel.image ? row.seriesUid : null,
      rowLimit: draft.rowLimit,
      entries: {FindKey.bodyPart: draft.entry(FindKey.bodyPart)},
    );
    parent = row;
    runId = null;
    selected = null;
    page = 0;
    collapsed = false;
    dateInputs.clear();
    dateError = null;
    error = null;
    scrollOffset = 0;
    _retain();
    notifyListeners();
  }

  void backTo(FindLevel level) {
    final previous = _parents[level];
    if (previous == null) return;
    _generation++;
    draft = previous.draft;
    runId = previous.runId;
    parent = previous.parent;
    _parents.removeWhere((k, v) => k.index >= level.index);
    selected = null;
    page = 0;
    dateInputs.clear();
    dateError = null;
    error = null;
    _retain();
    notifyListeners();
  }

  void _retain() => runner?.retainFindResults({
    ?runId,
    for (final p in _parents.values)
      if (p.runId != null) p.runId!,
  });
  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    runner?.retainFindResults({});
    super.dispose();
  }
}
