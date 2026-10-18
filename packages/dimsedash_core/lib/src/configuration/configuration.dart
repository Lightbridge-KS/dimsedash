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

/// Validation at the core boundary also protects non-widget callers.
Map<String, String> validateConfiguration(AppConfiguration config) {
  final errors = <String, String>{};
  void ae(String key, String value) {
    if (value.trim().isEmpty ||
        value != value.trim() ||
        !RegExp(r'^[\x20-\x5b\x5d-\x7e]{1,16}$').hasMatch(value)) {
      errors[key] =
          'Use 1–16 ASCII characters, without backslash or edge spaces.';
    }
  }

  void port(String key, int value) {
    if (value < 1 || value > 65535) errors[key] = 'Use a port from 1 to 65535.';
  }

  ae('callingAe', config.client.callingAe);
  port('listenPort', config.client.listenPort);
  final node = config.node;
  if (node != null) {
    if (node.label.trim().isEmpty || node.label.length > 100) {
      errors['label'] = 'Enter a node name of 1–100 characters.';
    }
    ae('calledAe', node.calledAe);
    port('pacsPort', node.port);
    if (!_validHost(node.host)) {
      errors['host'] = 'Enter a valid IP address or host name.';
    }
  }
  return Map.unmodifiable(errors);
}

bool _validHost(String host) {
  if (host.isEmpty || host.length > 253 || host != host.trim()) return false;
  if (host.contains(':')) {
    try {
      Uri.parse('http://[$host]/');
      return true;
    } on FormatException {
      return false;
    }
  }
  if (RegExp(r'^[0-9.]+$').hasMatch(host)) {
    final parts = host.split('.');
    return parts.length == 4 &&
        parts.every(
          (p) =>
              RegExp(r'^(0|[1-9][0-9]{0,2})$').hasMatch(p) &&
              int.parse(p) <= 255,
        );
  }
  return host
      .split('.')
      .every(
        (p) =>
            p.isNotEmpty &&
            p.length <= 63 &&
            RegExp(r'^[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?$').hasMatch(p),
      );
}
