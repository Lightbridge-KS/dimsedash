enum Appearance { system, light, dark }

enum NodeEnvironment { test, production }

final class ClientSettings {
  const ClientSettings({
    this.callingAe = 'DIMSE_DASH',
    this.listenPort = 11112,
    this.appearance = Appearance.system,
  });
  final String callingAe;
  final int listenPort;
  final Appearance appearance;
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

final class AppConfiguration {
  const AppConfiguration({
    this.client = const ClientSettings(),
    this.node,
    this.revision = 0,
  });
  final ClientSettings client;

  /// S0 edits one selected node. Multi-node management arrives in S1.
  final PacsNode? node;
  final int revision;
}
