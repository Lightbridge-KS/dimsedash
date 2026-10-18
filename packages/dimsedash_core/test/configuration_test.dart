import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:test/test.dart';

void main() {
  test('defaults have no peer and a valid local identity', () {
    const config = AppConfiguration();
    expect(config.node, isNull);
    expect(config.client.callingAe, 'DIMSE_DASH');
    expect(validateConfiguration(config), isEmpty);
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
