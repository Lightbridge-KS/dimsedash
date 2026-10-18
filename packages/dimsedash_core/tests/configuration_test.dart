import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:test/test.dart';

void main() {
  test('defaults have no peer and a valid local identity', () {
    const configuration = AppConfiguration();
    expect(configuration.node, isNull);
    expect(configuration.client.callingAe, 'DIMSE_DASH');
    expect(configuration.client.listenPort, 11112);
    expect(configuration.client.appearance, Appearance.system);
    expect(configuration.revision, 0);
    final node = config(host: '192.0.2.1');
    expect(node.node!.environment, NodeEnvironment.test);
    expect(node.node!.revision, 0);
    expect(validateConfiguration(configuration), isEmpty);
  });
  test('accepts field boundaries without normalizing node labels', () {
    for (final label in ['A', 'A' * 100, ' Synthetic ']) {
      final configuration = AppConfiguration(
        client: const ClientSettings(callingAe: 'A', listenPort: 1),
        node: PacsNode(
          id: '',
          label: label,
          calledAe: 'A' * 16,
          host: '192.0.2.1',
          port: 65535,
        ),
      );
      expect(validateConfiguration(configuration), isEmpty);
      expect(configuration.node!.label, label);
    }
  });
  test('preserves all error messages, field order and immutable results', () {
    final errors = validateConfiguration(
      const AppConfiguration(
        client: ClientSettings(callingAe: ' A ', listenPort: 0),
        node: PacsNode(
          id: '',
          label: ' ',
          calledAe: '',
          host: ' pacs.example ',
          port: 65536,
        ),
      ),
    );
    expect(errors, {
      'callingAe':
          'Use 1–16 ASCII characters, without backslash or edge spaces.',
      'listenPort': 'Use a port from 1 to 65535.',
      'label': 'Enter a node name of 1–100 characters.',
      'calledAe':
          'Use 1–16 ASCII characters, without backslash or edge spaces.',
      'pacsPort': 'Use a port from 1 to 65535.',
      'host': 'Enter a valid IP address or host name.',
    });
    expect(errors.keys.toList(), [
      'callingAe',
      'listenPort',
      'label',
      'calledAe',
      'pacsPort',
      'host',
    ]);
    expect(() => errors['host'] = 'changed', throwsUnsupportedError);
    expect(
      () => validateConfiguration(const AppConfiguration()).clear(),
      throwsUnsupportedError,
    );
  });
  for (final ae in ['', 'A' * 17, 'A\\B', 'A\nB', 'ไทย', ' A']) {
    test('rejects invalid local AE $ae', () {
      expect(
        validateConfiguration(
          AppConfiguration(client: ClientSettings(callingAe: ae)),
        ),
        contains('callingAe'),
      );
    });
  }
  for (final host in ['192.0.2.1', 'pacs.example', '::1', '2001:db8::1']) {
    test(
      'accepts address $host',
      () => expect(validateConfiguration(config(host: host)), isEmpty),
    );
  }
  for (final host in [
    '',
    'http://pacs',
    'pacs:104',
    '999.0.2.1',
    '1.2.3',
    'a..b',
    '-pacs',
    '::zz',
  ]) {
    test(
      'rejects malformed address $host',
      () => expect(validateConfiguration(config(host: host)), contains('host')),
    );
  }
  test('validates both ports and remote AE independently', () {
    final errors = validateConfiguration(
      AppConfiguration(
        client: const ClientSettings(listenPort: 0),
        node: const PacsNode(
          id: '',
          label: 'Test',
          calledAe: '',
          host: '192.0.2.1',
          port: 65536,
        ),
      ),
    );
    expect(errors.keys, containsAll(['listenPort', 'pacsPort', 'calledAe']));
    expect(() => errors.clear(), throwsUnsupportedError);
  });
}

AppConfiguration config({required String host}) => AppConfiguration(
  node: PacsNode(
    id: '',
    label: 'Synthetic',
    calledAe: 'PACS_AET',
    host: host,
    port: 104,
  ),
);
