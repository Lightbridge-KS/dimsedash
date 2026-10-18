import 'package:dimsedash_core/dimsedash_core.dart';

AppConfiguration draft({int revision = 0, String host = '192.0.2.1'}) =>
    AppConfiguration(
      revision: revision,
      client: const ClientSettings(
        callingAe: 'TEST_CLIENT',
        listenPort: 11113,
        appearance: Appearance.dark,
      ),
      node: PacsNode(
        id: '',
        label: 'Synthetic PACS',
        calledAe: 'PACS_AET',
        host: host,
        port: 104,
      ),
    );
