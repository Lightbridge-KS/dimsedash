import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/foundation.dart';

import 'retrieve_preview_model.dart';

/// A bounded session model with no configuration, transport, history or file seams.
class RetrievePreviewController extends ChangeNotifier {
  RetrievePreviewController(this.nodeId);
  final String nodeId;
  RetrieveDraft? _draft;
  RetrieveDraft get draft => _draft!;
  RetrieveSample? _latest;
  RetrieveSample? get latest => _latest;
  RetrieveScenario scenario = RetrieveScenario.complete;
  String? _receiverAe;
  int? _receiverPort;
  int _sequence = 0;
  int formRevision = 0;
  double reviewScroll = 0, runScroll = 0;
  final expanded = <String, bool>{};

  bool open(RetrieveSeed seed) {
    if (seed.node.id != nodeId || !seed.complete) return false;
    if (_draft?.seed.sourceId == seed.sourceId) return true;
    _draft = RetrieveDraft(seed: seed);
    scenario = RetrieveScenario.complete;
    _receiverAe = null;
    _receiverPort = null;
    reviewScroll = 0;
    expanded.clear();
    formRevision++;
    notifyListeners();
    return true;
  }

  void method(RetrieveMethod value) {
    _draft = draft.copy(method: value);
    if (value == RetrieveMethod.get && scenario.moveOnly) {
      scenario = RetrieveScenario.complete;
    }
    notifyListeners();
  }

  void chooseFolder(bool choose) {
    _draft = draft.copy(
      folder: choose ? 'Sample receive folder' : null,
      clearFolder: !choose,
    );
    notifyListeners();
  }

  void editUid(String key, String value) {
    if (!draft.seed.requiredKeys.contains(key)) return;
    _draft = draft.copy(uids: {...draft.uids, key: value});
    notifyListeners();
  }

  void resetIdentifier() {
    _draft = draft.copy(uids: draft.seed.uids);
    formRevision++;
    notifyListeners();
  }

  void setScenario(RetrieveScenario value) {
    if (value.moveOnly && draft.method != RetrieveMethod.move) return;
    scenario = value;
    notifyListeners();
  }

  bool receiverReady(AppConfiguration config) =>
      _receiverAe == config.client.callingAe &&
      _receiverPort == config.client.listenPort;
  void syncConfiguration(AppConfiguration config) {
    if (!receiverReady(config)) {
      _receiverAe = null;
      _receiverPort = null;
    }
  }

  void previewReceiver(AppConfiguration config) {
    _receiverAe = config.client.callingAe;
    _receiverPort = config.client.listenPort;
    notifyListeners();
  }

  String? blocked(AppConfiguration config, {required bool echoActive}) {
    if (echoActive) {
      return 'Echo is active. Wait for cleanup before changing a sample run.';
    }
    if (config.node?.id != nodeId) {
      return 'The preview node is no longer selected.';
    }
    if (draft.validation != null) return draft.validation;
    if (draft.folder == null) return 'Choose a sample folder first.';
    if (draft.method == RetrieveMethod.move && !receiverReady(config)) {
      return 'Preview receiver readiness first.';
    }
    return null;
  }

  String? showSample(AppConfiguration config, {required bool echoActive}) {
    final error = blocked(config, echoActive: echoActive);
    if (error != null) return error;
    _latest = RetrieveSample(
      id: 'retrieve-preview-${++_sequence}',
      request: RetrieveSnapshot(
        draft: draft,
        node: config.node!,
        client: config.client,
      ),
      scenario: scenario,
    );
    runScroll = 0;
    notifyListeners();
    return null;
  }

  bool transition(
    String id,
    RetrieveScenario value, {
    required bool echoActive,
  }) {
    if (echoActive ||
        _latest?.id != id ||
        !_latest!.transitional ||
        (value != RetrieveScenario.complete &&
            value != RetrieveScenario.cancelRequested)) {
      return false;
    }
    _latest = RetrieveSample(
      id: id,
      request: _latest!.request,
      scenario: value,
    );
    notifyListeners();
    return true;
  }
}
