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
  late NodeEnvironment _environment;
  bool _hasNode = false, _saving = false;
  String? _message;
  @override
  void initState() {
    super.initState();
    for (final key in [
      'callingAe',
      'listenPort',
      'label',
      'calledAe',
      'host',
      'pacsPort',
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
          'Connection settings are stored locally. Apply sends no network traffic.',
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DICOM connection', style: theme.textTheme.titleLarge),
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
                  helperText: 'Default AE: DIMSE_DASH. This identity also serves the local receiver and C-MOVE destination. C-GET needs no separate listener.',
                ),
                const Divider(height: 32),
                _ConnectionSection(
                  header: _base.node == null
                      ? CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Configure a remote PACS'),
                          value: _hasNode,
                          onChanged: _saving
                              ? null
                              : (value) => setState(() => _hasNode = value!),
                        )
                      : Text(
                          'Remote PACS · selected node',
                          style: theme.textTheme.titleMedium,
                        ),
                  showFields: _hasNode,
                  fields: _hasNode
                      ? [
                          _field('Node name', 'label'),
                          _field('Called AE Title', 'calledAe'),
                          _field('PACS IP address / host', 'host'),
                          _field('PACS port', 'pacsPort', number: true),
                          _EnumSettingField<NodeEnvironment>(
                            label: 'Environment',
                            value: _environment,
                            values: NodeEnvironment.values,
                            onChanged: _saving
                                ? null
                                : (value) =>
                                      setState(() => _environment = value!),
                          ),
                        ]
                      : const [],
                  helperText: 'For C-MOVE, register the client AE, reachable address and listening port on the PACS. Applying these settings does not update that registration.',
                ),
                const Divider(height: 32),
                _EnumSettingField<Appearance>(
                  label: 'Appearance',
                  value: _appearance,
                  values: Appearance.values,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _appearance = value!),
                ),
                const SizedBox(height: 20),
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
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Saving…' : 'Apply connection'),
                    ),
                    OutlinedButton(
                      onPressed: _saving ? null : () => setState(_restore),
                      child: const Text('Discard edits'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Receiver stopped. Networking and receiving will be available in a later preview.',
        ),
      ],
    );
  }

  void _restore() {
    _base = ref.read(configurationProvider);
    _appearance = _base.client.appearance;
    _environment = _base.node?.environment ?? NodeEnvironment.test;
    _hasNode = _base.node != null;
    final values = {
      'callingAe': _base.client.callingAe,
      'listenPort': '${_base.client.listenPort}',
      'label': _base.node?.label ?? '',
      'calledAe': _base.node?.calledAe ?? '',
      'host': _base.node?.host ?? '',
      'pacsPort': _base.node?.port.toString() ?? '',
    };
    for (final entry in values.entries) {
      _controllers[entry.key]!.text = entry.value;
    }
    _errors = {};
    _message = null;
  }

  Future<void> _save() async {
    if (_saving) return;
    String value(String k) => _controllers[k]!.text.trim();
    final draft = AppConfiguration(
      revision: _base.revision,
      client: ClientSettings(
        callingAe: value('callingAe'),
        listenPort: int.tryParse(value('listenPort')) ?? 0,
        appearance: _appearance,
      ),
      node: !_hasNode
          ? null
          : PacsNode(
              id: _base.node?.id ?? '',
              label: value('label'),
              calledAe: value('calledAe'),
              host: value('host'),
              port: int.tryParse(value('pacsPort')) ?? 0,
              environment: _environment,
              revision: _base.node?.revision ?? 0,
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
      final failure = await ref
          .read(configurationProvider.notifier)
          .save(draft);
      if (!mounted) return;
      setState(() {
        if (failure == null) _restore();
        _message =
            failure?.message ?? 'Connection saved. No network request sent.';
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
      enabled: !_saving,
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

class _EnumSettingField<T extends Enum> extends StatelessWidget {
  const _EnumSettingField({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: DropdownButtonFormField<T>(
        key: ValueKey(value),
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: values
            .map((e) => DropdownMenuItem<T>(value: e, child: Text(e.name)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _ConnectionSection extends StatelessWidget {
  const _ConnectionSection({
    required this.header,
    required this.fields,
    required this.helperText,
    this.showFields = true,
  });

  final Widget header;
  final List<Widget> fields;
  final String helperText;
  final bool showFields;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        if (showFields) ...[
          const SizedBox(height: 16),
          Wrap(spacing: 16, runSpacing: 16, children: fields),
          const SizedBox(height: 12),
          Text(helperText),
        ],
      ],
    );
  }
}
