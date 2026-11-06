import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bindings/configuration.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});
  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  final _controllers = <String, TextEditingController>{};
  Map<String, String> _errors = {};
  late AppConfiguration _base;
  late Appearance _appearance;
  bool _saving = false;
  bool _reloading = false;
  bool get _busy => _saving || _reloading;
  String? _message;
  @override
  void initState() {
    super.initState();
    for (final key in [
      'callingAe',
      'listenPort',
      'connect',
      'association',
      'dimse',
      'idle',
    ]) {
      _controllers[key] = TextEditingController();
    }
    _restore();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Settings & storage', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text(
          'Global settings are stored locally. Saving sends no network traffic.',
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('General', style: theme.textTheme.titleLarge),
                const SizedBox(height: 20),
                _ThemeSetting(
                  value: _appearance,
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _appearance = value),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Local DICOM settings', style: theme.textTheme.titleLarge),
                const SizedBox(height: 20),
                _ConnectionSection(
                  header: Text(
                    'Client node',
                    style: theme.textTheme.titleMedium,
                  ),
                  fields: [
                    _field('Calling AE Title', 'callingAe'),
                    _field(
                      'Client listening port · C-MOVE',
                      'listenPort',
                      number: true,
                    ),
                  ],
                  helperText: 'Default AE: DIMSE_DASH. This identity also serves the local receiver and C-MOVE destination. C-GET needs no separate listener. For C-MOVE, register this client AE, reachable address and listening port on the PACS. Saving local settings does not update that registration.',
                ),
                const Divider(height: 32),
                ...[
                  Text(
                    'Global DICOM timeouts · seconds',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (final key in [
                        'connect',
                        'association',
                        'dimse',
                        'idle',
                      ])
                        _field(
                          '${key[0].toUpperCase()}${key.substring(1)} timeout',
                          key,
                          number: true,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_message != null)
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(_message!),
            ),
          ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save settings'),
            ),
            OutlinedButton(
              onPressed: _busy ? null : _discard,
              child: Text(_reloading ? 'Reloading…' : 'Discard edits'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Receiver stopped. Receiving will be available in a later preview.',
        ),
      ],
    );
  }

  void _restore() {
    _base = ref.read(configurationProvider);
    _appearance = _base.client.appearance;
    final values = {
      for (final entry in _base.client.timeouts.values.entries)
        entry.key: '${entry.value}',
      'callingAe': _base.client.callingAe,
      'listenPort': '${_base.client.listenPort}',
    };
    for (final entry in values.entries) {
      _controllers[entry.key]!.text = entry.value;
    }
    _errors = {};
    _message = null;
  }

  Future<void> _discard() async {
    if (_busy) return;
    setState(() => _reloading = true);
    try {
      final failure = await ref.read(configurationProvider.notifier).reload();
      if (!mounted) return;
      setState(() {
        if (failure == null) {
          _restore();
        } else {
          _message = failure.message;
        }
      });
    } finally {
      if (mounted) setState(() => _reloading = false);
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    String value(String k) => _controllers[k]!.text.trim();
    final draft = AppConfiguration(
      revision: _base.revision,
      client: ClientSettings(
        callingAe: value('callingAe'),
        listenPort: int.tryParse(value('listenPort')) ?? 0,
        appearance: _appearance,
        timeouts: EchoTimeouts(
          connect: int.tryParse(value('connect')) ?? 0,
          association: int.tryParse(value('association')) ?? 0,
          dimse: int.tryParse(value('dimse')) ?? 0,
          idle: int.tryParse(value('idle')) ?? 0,
        ),
      ),
    );
    final errors = validateConfiguration(draft);
    setState(() {
      _errors = errors;
      _message = null;
    });
    if (errors.isNotEmpty) return;
    setState(() => _saving = true);
    try {
      final controller = ref.read(configurationProvider.notifier);
      final failure = await controller.saveClientSettings(
        draft.client,
        expectedRevision: _base.revision,
      );
      if (!mounted) return;
      setState(() {
        if (failure == null) _restore();
        _message =
            failure?.message ?? 'Settings saved. No network request sent.';
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(String label, String key, {bool number = false}) => SizedBox(
    width: 300,
    child: TextField(
      key: ValueKey(key),
      controller: _controllers[key],
      enabled: !_busy,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(
        labelText: label,
        errorText: _errors[key],
        errorMaxLines: 3,
      ),
    ),
  );
}

class _ThemeSetting extends StatelessWidget {
  const _ThemeSetting({required this.value, required this.onChanged});

  final Appearance value;
  final ValueChanged<Appearance>? onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Theme', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, constraints) => SegmentedButton<Appearance>(
          direction:
              constraints.maxWidth < MediaQuery.textScalerOf(context).scale(360)
              ? Axis.vertical
              : Axis.horizontal,
          segments: const [
            ButtonSegment(
              value: Appearance.system,
              icon: Icon(Icons.brightness_auto_outlined),
              label: Text('System'),
            ),
            ButtonSegment(
              value: Appearance.light,
              icon: Icon(Icons.light_mode_outlined),
              label: Text('Light'),
            ),
            ButtonSegment(
              value: Appearance.dark,
              icon: Icon(Icons.dark_mode_outlined),
              label: Text('Dark'),
            ),
          ],
          selected: {value},
          onSelectionChanged: onChanged == null
              ? null
              : (selection) => onChanged!(selection.single),
        ),
      ),
      const SizedBox(height: 8),
      Text(switch (value) {
        Appearance.system => 'Follow the system’s appearance.',
        Appearance.light => 'Always use light appearance.',
        Appearance.dark => 'Always use dark appearance.',
      }, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _ConnectionSection extends StatelessWidget {
  const _ConnectionSection({
    required this.header,
    required this.fields,
    required this.helperText,
  });

  final Widget header;
  final List<Widget> fields;
  final String helperText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        ...[
          const SizedBox(height: 16),
          Wrap(spacing: 16, runSpacing: 16, children: fields),
          const SizedBox(height: 12),
          Text(helperText),
        ],
      ],
    );
  }
}
