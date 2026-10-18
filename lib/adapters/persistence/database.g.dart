// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $NodesTable extends Nodes with TableInfo<$NodesTable, Node> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _calledAeMeta = const VerificationMeta(
    'calledAe',
  );
  @override
  late final GeneratedColumn<String> calledAe = GeneratedColumn<String>(
    'called_ae',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hostMeta = const VerificationMeta('host');
  @override
  late final GeneratedColumn<String> host = GeneratedColumn<String>(
    'host',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _portMeta = const VerificationMeta('port');
  @override
  late final GeneratedColumn<int> port = GeneratedColumn<int>(
    'port',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _environmentMeta = const VerificationMeta(
    'environment',
  );
  @override
  late final GeneratedColumn<String> environment = GeneratedColumn<String>(
    'environment',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    label,
    calledAe,
    host,
    port,
    environment,
    revision,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Node> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('called_ae')) {
      context.handle(
        _calledAeMeta,
        calledAe.isAcceptableOrUnknown(data['called_ae']!, _calledAeMeta),
      );
    } else if (isInserting) {
      context.missing(_calledAeMeta);
    }
    if (data.containsKey('host')) {
      context.handle(
        _hostMeta,
        host.isAcceptableOrUnknown(data['host']!, _hostMeta),
      );
    } else if (isInserting) {
      context.missing(_hostMeta);
    }
    if (data.containsKey('port')) {
      context.handle(
        _portMeta,
        port.isAcceptableOrUnknown(data['port']!, _portMeta),
      );
    } else if (isInserting) {
      context.missing(_portMeta);
    }
    if (data.containsKey('environment')) {
      context.handle(
        _environmentMeta,
        environment.isAcceptableOrUnknown(
          data['environment']!,
          _environmentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_environmentMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Node map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Node(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      calledAe: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}called_ae'],
      )!,
      host: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}host'],
      )!,
      port: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}port'],
      )!,
      environment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}environment'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
    );
  }

  @override
  $NodesTable createAlias(String alias) {
    return $NodesTable(attachedDatabase, alias);
  }
}

class Node extends DataClass implements Insertable<Node> {
  final String id;
  final String label;
  final String calledAe;
  final String host;
  final int port;
  final String environment;
  final int revision;
  const Node({
    required this.id,
    required this.label,
    required this.calledAe,
    required this.host,
    required this.port,
    required this.environment,
    required this.revision,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['label'] = Variable<String>(label);
    map['called_ae'] = Variable<String>(calledAe);
    map['host'] = Variable<String>(host);
    map['port'] = Variable<int>(port);
    map['environment'] = Variable<String>(environment);
    map['revision'] = Variable<int>(revision);
    return map;
  }

  NodesCompanion toCompanion(bool nullToAbsent) {
    return NodesCompanion(
      id: Value(id),
      label: Value(label),
      calledAe: Value(calledAe),
      host: Value(host),
      port: Value(port),
      environment: Value(environment),
      revision: Value(revision),
    );
  }

  factory Node.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Node(
      id: serializer.fromJson<String>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      calledAe: serializer.fromJson<String>(json['calledAe']),
      host: serializer.fromJson<String>(json['host']),
      port: serializer.fromJson<int>(json['port']),
      environment: serializer.fromJson<String>(json['environment']),
      revision: serializer.fromJson<int>(json['revision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'label': serializer.toJson<String>(label),
      'calledAe': serializer.toJson<String>(calledAe),
      'host': serializer.toJson<String>(host),
      'port': serializer.toJson<int>(port),
      'environment': serializer.toJson<String>(environment),
      'revision': serializer.toJson<int>(revision),
    };
  }

  Node copyWith({
    String? id,
    String? label,
    String? calledAe,
    String? host,
    int? port,
    String? environment,
    int? revision,
  }) => Node(
    id: id ?? this.id,
    label: label ?? this.label,
    calledAe: calledAe ?? this.calledAe,
    host: host ?? this.host,
    port: port ?? this.port,
    environment: environment ?? this.environment,
    revision: revision ?? this.revision,
  );
  Node copyWithCompanion(NodesCompanion data) {
    return Node(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      calledAe: data.calledAe.present ? data.calledAe.value : this.calledAe,
      host: data.host.present ? data.host.value : this.host,
      port: data.port.present ? data.port.value : this.port,
      environment: data.environment.present
          ? data.environment.value
          : this.environment,
      revision: data.revision.present ? data.revision.value : this.revision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Node(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('calledAe: $calledAe, ')
          ..write('host: $host, ')
          ..write('port: $port, ')
          ..write('environment: $environment, ')
          ..write('revision: $revision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, label, calledAe, host, port, environment, revision);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Node &&
          other.id == this.id &&
          other.label == this.label &&
          other.calledAe == this.calledAe &&
          other.host == this.host &&
          other.port == this.port &&
          other.environment == this.environment &&
          other.revision == this.revision);
}

class NodesCompanion extends UpdateCompanion<Node> {
  final Value<String> id;
  final Value<String> label;
  final Value<String> calledAe;
  final Value<String> host;
  final Value<int> port;
  final Value<String> environment;
  final Value<int> revision;
  final Value<int> rowid;
  const NodesCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.calledAe = const Value.absent(),
    this.host = const Value.absent(),
    this.port = const Value.absent(),
    this.environment = const Value.absent(),
    this.revision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NodesCompanion.insert({
    required String id,
    required String label,
    required String calledAe,
    required String host,
    required int port,
    required String environment,
    required int revision,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       label = Value(label),
       calledAe = Value(calledAe),
       host = Value(host),
       port = Value(port),
       environment = Value(environment),
       revision = Value(revision);
  static Insertable<Node> custom({
    Expression<String>? id,
    Expression<String>? label,
    Expression<String>? calledAe,
    Expression<String>? host,
    Expression<int>? port,
    Expression<String>? environment,
    Expression<int>? revision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (calledAe != null) 'called_ae': calledAe,
      if (host != null) 'host': host,
      if (port != null) 'port': port,
      if (environment != null) 'environment': environment,
      if (revision != null) 'revision': revision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NodesCompanion copyWith({
    Value<String>? id,
    Value<String>? label,
    Value<String>? calledAe,
    Value<String>? host,
    Value<int>? port,
    Value<String>? environment,
    Value<int>? revision,
    Value<int>? rowid,
  }) {
    return NodesCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      calledAe: calledAe ?? this.calledAe,
      host: host ?? this.host,
      port: port ?? this.port,
      environment: environment ?? this.environment,
      revision: revision ?? this.revision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (calledAe.present) {
      map['called_ae'] = Variable<String>(calledAe.value);
    }
    if (host.present) {
      map['host'] = Variable<String>(host.value);
    }
    if (port.present) {
      map['port'] = Variable<int>(port.value);
    }
    if (environment.present) {
      map['environment'] = Variable<String>(environment.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NodesCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('calledAe: $calledAe, ')
          ..write('host: $host, ')
          ..write('port: $port, ')
          ..write('environment: $environment, ')
          ..write('revision: $revision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _callingAeMeta = const VerificationMeta(
    'callingAe',
  );
  @override
  late final GeneratedColumn<String> callingAe = GeneratedColumn<String>(
    'calling_ae',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _listenPortMeta = const VerificationMeta(
    'listenPort',
  );
  @override
  late final GeneratedColumn<int> listenPort = GeneratedColumn<int>(
    'listen_port',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appearanceMeta = const VerificationMeta(
    'appearance',
  );
  @override
  late final GeneratedColumn<String> appearance = GeneratedColumn<String>(
    'appearance',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _selectedNodeIdMeta = const VerificationMeta(
    'selectedNodeId',
  );
  @override
  late final GeneratedColumn<String> selectedNodeId = GeneratedColumn<String>(
    'selected_node_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES nodes (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    callingAe,
    listenPort,
    appearance,
    revision,
    selectedNodeId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('calling_ae')) {
      context.handle(
        _callingAeMeta,
        callingAe.isAcceptableOrUnknown(data['calling_ae']!, _callingAeMeta),
      );
    } else if (isInserting) {
      context.missing(_callingAeMeta);
    }
    if (data.containsKey('listen_port')) {
      context.handle(
        _listenPortMeta,
        listenPort.isAcceptableOrUnknown(data['listen_port']!, _listenPortMeta),
      );
    } else if (isInserting) {
      context.missing(_listenPortMeta);
    }
    if (data.containsKey('appearance')) {
      context.handle(
        _appearanceMeta,
        appearance.isAcceptableOrUnknown(data['appearance']!, _appearanceMeta),
      );
    } else if (isInserting) {
      context.missing(_appearanceMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('selected_node_id')) {
      context.handle(
        _selectedNodeIdMeta,
        selectedNodeId.isAcceptableOrUnknown(
          data['selected_node_id']!,
          _selectedNodeIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      callingAe: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}calling_ae'],
      )!,
      listenPort: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}listen_port'],
      )!,
      appearance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}appearance'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      selectedNodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selected_node_id'],
      ),
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final int id;
  final String callingAe;
  final int listenPort;
  final String appearance;
  final int revision;
  final String? selectedNodeId;
  const AppSetting({
    required this.id,
    required this.callingAe,
    required this.listenPort,
    required this.appearance,
    required this.revision,
    this.selectedNodeId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['calling_ae'] = Variable<String>(callingAe);
    map['listen_port'] = Variable<int>(listenPort);
    map['appearance'] = Variable<String>(appearance);
    map['revision'] = Variable<int>(revision);
    if (!nullToAbsent || selectedNodeId != null) {
      map['selected_node_id'] = Variable<String>(selectedNodeId);
    }
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      callingAe: Value(callingAe),
      listenPort: Value(listenPort),
      appearance: Value(appearance),
      revision: Value(revision),
      selectedNodeId: selectedNodeId == null && nullToAbsent
          ? const Value.absent()
          : Value(selectedNodeId),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      id: serializer.fromJson<int>(json['id']),
      callingAe: serializer.fromJson<String>(json['callingAe']),
      listenPort: serializer.fromJson<int>(json['listenPort']),
      appearance: serializer.fromJson<String>(json['appearance']),
      revision: serializer.fromJson<int>(json['revision']),
      selectedNodeId: serializer.fromJson<String?>(json['selectedNodeId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'callingAe': serializer.toJson<String>(callingAe),
      'listenPort': serializer.toJson<int>(listenPort),
      'appearance': serializer.toJson<String>(appearance),
      'revision': serializer.toJson<int>(revision),
      'selectedNodeId': serializer.toJson<String?>(selectedNodeId),
    };
  }

  AppSetting copyWith({
    int? id,
    String? callingAe,
    int? listenPort,
    String? appearance,
    int? revision,
    Value<String?> selectedNodeId = const Value.absent(),
  }) => AppSetting(
    id: id ?? this.id,
    callingAe: callingAe ?? this.callingAe,
    listenPort: listenPort ?? this.listenPort,
    appearance: appearance ?? this.appearance,
    revision: revision ?? this.revision,
    selectedNodeId: selectedNodeId.present
        ? selectedNodeId.value
        : this.selectedNodeId,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      id: data.id.present ? data.id.value : this.id,
      callingAe: data.callingAe.present ? data.callingAe.value : this.callingAe,
      listenPort: data.listenPort.present
          ? data.listenPort.value
          : this.listenPort,
      appearance: data.appearance.present
          ? data.appearance.value
          : this.appearance,
      revision: data.revision.present ? data.revision.value : this.revision,
      selectedNodeId: data.selectedNodeId.present
          ? data.selectedNodeId.value
          : this.selectedNodeId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('callingAe: $callingAe, ')
          ..write('listenPort: $listenPort, ')
          ..write('appearance: $appearance, ')
          ..write('revision: $revision, ')
          ..write('selectedNodeId: $selectedNodeId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    callingAe,
    listenPort,
    appearance,
    revision,
    selectedNodeId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.callingAe == this.callingAe &&
          other.listenPort == this.listenPort &&
          other.appearance == this.appearance &&
          other.revision == this.revision &&
          other.selectedNodeId == this.selectedNodeId);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> id;
  final Value<String> callingAe;
  final Value<int> listenPort;
  final Value<String> appearance;
  final Value<int> revision;
  final Value<String?> selectedNodeId;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.callingAe = const Value.absent(),
    this.listenPort = const Value.absent(),
    this.appearance = const Value.absent(),
    this.revision = const Value.absent(),
    this.selectedNodeId = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    required String callingAe,
    required int listenPort,
    required String appearance,
    required int revision,
    this.selectedNodeId = const Value.absent(),
  }) : callingAe = Value(callingAe),
       listenPort = Value(listenPort),
       appearance = Value(appearance),
       revision = Value(revision);
  static Insertable<AppSetting> custom({
    Expression<int>? id,
    Expression<String>? callingAe,
    Expression<int>? listenPort,
    Expression<String>? appearance,
    Expression<int>? revision,
    Expression<String>? selectedNodeId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (callingAe != null) 'calling_ae': callingAe,
      if (listenPort != null) 'listen_port': listenPort,
      if (appearance != null) 'appearance': appearance,
      if (revision != null) 'revision': revision,
      if (selectedNodeId != null) 'selected_node_id': selectedNodeId,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? callingAe,
    Value<int>? listenPort,
    Value<String>? appearance,
    Value<int>? revision,
    Value<String?>? selectedNodeId,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      callingAe: callingAe ?? this.callingAe,
      listenPort: listenPort ?? this.listenPort,
      appearance: appearance ?? this.appearance,
      revision: revision ?? this.revision,
      selectedNodeId: selectedNodeId ?? this.selectedNodeId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (callingAe.present) {
      map['calling_ae'] = Variable<String>(callingAe.value);
    }
    if (listenPort.present) {
      map['listen_port'] = Variable<int>(listenPort.value);
    }
    if (appearance.present) {
      map['appearance'] = Variable<String>(appearance.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (selectedNodeId.present) {
      map['selected_node_id'] = Variable<String>(selectedNodeId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('callingAe: $callingAe, ')
          ..write('listenPort: $listenPort, ')
          ..write('appearance: $appearance, ')
          ..write('revision: $revision, ')
          ..write('selectedNodeId: $selectedNodeId')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $NodesTable nodes = $NodesTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [nodes, appSettings];
}

typedef $$NodesTableCreateCompanionBuilder = NodesCompanion Function({
  required String id,
  required String label,
  required String calledAe,
  required String host,
  required int port,
  required String environment,
  required int revision,
  Value<int> rowid,
});
typedef $$NodesTableUpdateCompanionBuilder = NodesCompanion Function({
  Value<String> id,
  Value<String> label,
  Value<String> calledAe,
  Value<String> host,
  Value<int> port,
  Value<String> environment,
  Value<int> revision,
  Value<int> rowid,
});

final class $$NodesTableReferences
    extends BaseReferences<_$AppDatabase, $NodesTable, Node> {
  $$NodesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AppSettingsTable, List<AppSetting>>
  _appSettingsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.appSettings,
    aliasName: 'nodes__id__app_settings__selected_node_id',
  );

  $$AppSettingsTableProcessedTableManager get appSettingsRefs {
    final manager = $$AppSettingsTableTableManager(
      $_db,
      $_db.appSettings,
    ).filter((f) => f.selectedNodeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_appSettingsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$NodesTableFilterComposer extends Composer<_$AppDatabase, $NodesTable> {
  $$NodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get calledAe => $composableBuilder(
    column: $table.calledAe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get environment => $composableBuilder(
    column: $table.environment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> appSettingsRefs(
    Expression<bool> Function($$AppSettingsTableFilterComposer f) f,
  ) {
    final $$AppSettingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.appSettings,
      getReferencedColumn: (t) => t.selectedNodeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AppSettingsTableFilterComposer(
            $db: $db,
            $table: $db.appSettings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NodesTableOrderingComposer
    extends Composer<_$AppDatabase, $NodesTable> {
  $$NodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get calledAe => $composableBuilder(
    column: $table.calledAe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get environment => $composableBuilder(
    column: $table.environment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NodesTable> {
  $$NodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get calledAe =>
      $composableBuilder(column: $table.calledAe, builder: (column) => column);

  GeneratedColumn<String> get host =>
      $composableBuilder(column: $table.host, builder: (column) => column);

  GeneratedColumn<int> get port =>
      $composableBuilder(column: $table.port, builder: (column) => column);

  GeneratedColumn<String> get environment => $composableBuilder(
    column: $table.environment,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  Expression<T> appSettingsRefs<T extends Object>(
    Expression<T> Function($$AppSettingsTableAnnotationComposer a) f,
  ) {
    final $$AppSettingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.appSettings,
      getReferencedColumn: (t) => t.selectedNodeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AppSettingsTableAnnotationComposer(
            $db: $db,
            $table: $db.appSettings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NodesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NodesTable,
          Node,
          $$NodesTableFilterComposer,
          $$NodesTableOrderingComposer,
          $$NodesTableAnnotationComposer,
          $$NodesTableCreateCompanionBuilder,
          $$NodesTableUpdateCompanionBuilder,
          (Node, $$NodesTableReferences),
          Node,
          PrefetchHooks Function({bool appSettingsRefs})
        > {
  $$NodesTableTableManager(_$AppDatabase db, $NodesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> calledAe = const Value.absent(),
                Value<String> host = const Value.absent(),
                Value<int> port = const Value.absent(),
                Value<String> environment = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NodesCompanion(
                id: id,
                label: label,
                calledAe: calledAe,
                host: host,
                port: port,
                environment: environment,
                revision: revision,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String label,
                required String calledAe,
                required String host,
                required int port,
                required String environment,
                required int revision,
                Value<int> rowid = const Value.absent(),
              }) => NodesCompanion.insert(
                id: id,
                label: label,
                calledAe: calledAe,
                host: host,
                port: port,
                environment: environment,
                revision: revision,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NodesTable, Node>(table),
                  $$NodesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({appSettingsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (appSettingsRefs) db.appSettings],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (appSettingsRefs)
                    await $_getPrefetchedData<Node, $NodesTable, AppSetting>(
                      currentTable: table,
                      referencedTable: $$NodesTableReferences
                          ._appSettingsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$NodesTableReferences(db, table, p0).appSettingsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.selectedNodeId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$NodesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NodesTable,
      Node,
      $$NodesTableFilterComposer,
      $$NodesTableOrderingComposer,
      $$NodesTableAnnotationComposer,
      $$NodesTableCreateCompanionBuilder,
      $$NodesTableUpdateCompanionBuilder,
      (Node, $$NodesTableReferences),
      Node,
      PrefetchHooks Function({bool appSettingsRefs})
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      required String callingAe,
      required int listenPort,
      required String appearance,
      required int revision,
      Value<String?> selectedNodeId,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String> callingAe,
      Value<int> listenPort,
      Value<String> appearance,
      Value<int> revision,
      Value<String?> selectedNodeId,
    });

final class $$AppSettingsTableReferences
    extends BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting> {
  $$AppSettingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $NodesTable _selectedNodeIdTable(_$AppDatabase db) =>
      db.nodes.createAlias('app_settings__selected_node_id__nodes__id');

  $$NodesTableProcessedTableManager? get selectedNodeId {
    final $_column = $_itemColumn<String>('selected_node_id');
    if ($_column == null) return null;
    final manager = $$NodesTableTableManager(
      $_db,
      $_db.nodes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_selectedNodeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get callingAe => $composableBuilder(
    column: $table.callingAe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get listenPort => $composableBuilder(
    column: $table.listenPort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appearance => $composableBuilder(
    column: $table.appearance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  $$NodesTableFilterComposer get selectedNodeId {
    final $$NodesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.selectedNodeId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableFilterComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get callingAe => $composableBuilder(
    column: $table.callingAe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get listenPort => $composableBuilder(
    column: $table.listenPort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appearance => $composableBuilder(
    column: $table.appearance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  $$NodesTableOrderingComposer get selectedNodeId {
    final $$NodesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.selectedNodeId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableOrderingComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get callingAe =>
      $composableBuilder(column: $table.callingAe, builder: (column) => column);

  GeneratedColumn<int> get listenPort => $composableBuilder(
    column: $table.listenPort,
    builder: (column) => column,
  );

  GeneratedColumn<String> get appearance => $composableBuilder(
    column: $table.appearance,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  $$NodesTableAnnotationComposer get selectedNodeId {
    final $$NodesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.selectedNodeId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableAnnotationComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (AppSetting, $$AppSettingsTableReferences),
          AppSetting,
          PrefetchHooks Function({bool selectedNodeId})
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> callingAe = const Value.absent(),
                Value<int> listenPort = const Value.absent(),
                Value<String> appearance = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<String?> selectedNodeId = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                callingAe: callingAe,
                listenPort: listenPort,
                appearance: appearance,
                revision: revision,
                selectedNodeId: selectedNodeId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String callingAe,
                required int listenPort,
                required String appearance,
                required int revision,
                Value<String?> selectedNodeId = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                callingAe: callingAe,
                listenPort: listenPort,
                appearance: appearance,
                revision: revision,
                selectedNodeId: selectedNodeId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSetting>(table),
                  $$AppSettingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({selectedNodeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (selectedNodeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.selectedNodeId,
                        referencedTable: $$AppSettingsTableReferences
                            ._selectedNodeIdTable(db),
                        referencedColumn: $$AppSettingsTableReferences
                            ._selectedNodeIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (AppSetting, $$AppSettingsTableReferences),
      AppSetting,
      PrefetchHooks Function({bool selectedNodeId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$NodesTableTableManager get nodes =>
      $$NodesTableTableManager(_db, _db.nodes);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
