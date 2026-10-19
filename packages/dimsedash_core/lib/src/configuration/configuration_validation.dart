import 'configuration.dart';

/// Validation at the core boundary also protects non-widget callers.
Map<String, String> validateConfiguration(AppConfiguration config) {
  final errors = <String, String>{};
  void validateAe(String key, String value) {
    if (value.trim().isEmpty ||
        value != value.trim() ||
        !RegExp(r'^[\x20-\x5b\x5d-\x7e]{1,16}$').hasMatch(value)) {
      errors[key] =
          'Use 1–16 ASCII characters, without backslash or edge spaces.';
    }
  }

  void validatePort(String key, int value) {
    if (value < 1 || value > 65535) errors[key] = 'Use a port from 1 to 65535.';
  }

  validateAe('callingAe', config.client.callingAe);
  validatePort('listenPort', config.client.listenPort);
  for (final entry in config.client.timeouts.values.entries) {
    if (entry.value < 1 || entry.value > 600) {
      errors[entry.key] = 'Use whole seconds from 1 to 600.';
    }
  }
  final node = config.node;
  if (node != null) {
    if (node.label.trim().isEmpty || node.label.length > 100) {
      errors['label'] = 'Enter a node name of 1–100 characters.';
    }
    validateAe('calledAe', node.calledAe);
    validatePort('pacsPort', node.port);
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
