enum Appearance { system, light, dark }

enum NodeEnvironment { test, production }

final class ClientSettings {
  const ClientSettings({
    this.callingAe = 'DIMSE_DASH',
    this.listenPort = 11112,
    this.appearance = Appearance.system,
    this.timeouts = const EchoTimeouts(),
  });
  final String callingAe;
  final int listenPort;
  final Appearance appearance;
  final EchoTimeouts timeouts;
}

final class PacsNode {
  const PacsNode({
    required this.id,
    required this.label,
    required this.calledAe,
    required this.host,
    required this.port,
    this.environment = NodeEnvironment.test,
    this.revision = 0,
  });
  final String id;
  final String label;
  final String calledAe;
  final String host;
  final int port;
  final NodeEnvironment environment;
  final int revision;
}

final class EchoTimeouts {
  const EchoTimeouts({
    this.connect = 30,
    this.association = 30,
    this.dimse = 30,
    this.idle = 60,
  });
  final int connect, association, dimse, idle;
  Map<String, int> get values => {
    'connect': connect,
    'association': association,
    'dimse': dimse,
    'idle': idle,
  };
}

final class AppConfiguration {
  const AppConfiguration({
    this.client = const ClientSettings(),
    this._node,
    this._nodes = const [],
    this._selectedNodeId,
    this.revision = 0,
  });
  final ClientSettings client;
  final PacsNode? _node;
  final List<PacsNode> _nodes;
  final String? _selectedNodeId;
  List<PacsNode> get nodes =>
      List.unmodifiable(_node != null && _nodes.isEmpty ? [_node] : _nodes);
  String? get selectedNodeId => _node?.id ?? _selectedNodeId;
  PacsNode? get node =>
      _node ?? _nodes.where((n) => n.id == _selectedNodeId).firstOrNull;
  final int revision;
  List<PacsNode> searchNodes(String query) {
    final text = query.trim().toLowerCase();
    final matches = nodes
        .where(
          (n) => [
            n.label,
            n.host,
            n.calledAe,
          ].any((v) => v.toLowerCase().contains(text)),
        )
        .toList();
    matches.sort((a, b) {
      final label = a.label.toLowerCase().compareTo(b.label.toLowerCase());
      return label != 0 ? label : a.id.compareTo(b.id);
    });
    return List.unmodifiable(matches);
  }
}

/// Duplication never writes or selects until the draft is explicitly saved.
PacsNode duplicateNode(PacsNode source) => PacsNode(
  id: '',
  label: '${source.label} copy',
  calledAe: source.calledAe,
  host: source.host,
  port: source.port,
  environment: source.environment,
);
