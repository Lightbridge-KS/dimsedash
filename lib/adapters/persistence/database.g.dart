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
  static const VerificationMeta _connectTimeoutMeta = const VerificationMeta(
    'connectTimeout',
  );
  @override
  late final GeneratedColumn<int> connectTimeout = GeneratedColumn<int>(
    'connect_timeout',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(30),
  );
  static const VerificationMeta _associationTimeoutMeta =
      const VerificationMeta('associationTimeout');
  @override
  late final GeneratedColumn<int> associationTimeout = GeneratedColumn<int>(
    'association_timeout',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(30),
  );
  static const VerificationMeta _dimseTimeoutMeta = const VerificationMeta(
    'dimseTimeout',
  );
  @override
  late final GeneratedColumn<int> dimseTimeout = GeneratedColumn<int>(
    'dimse_timeout',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(30),
  );
  static const VerificationMeta _idleTimeoutMeta = const VerificationMeta(
    'idleTimeout',
  );
  @override
  late final GeneratedColumn<int> idleTimeout = GeneratedColumn<int>(
    'idle_timeout',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(60),
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
    connectTimeout,
    associationTimeout,
    dimseTimeout,
    idleTimeout,
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
    if (data.containsKey('connect_timeout')) {
      context.handle(
        _connectTimeoutMeta,
        connectTimeout.isAcceptableOrUnknown(
          data['connect_timeout']!,
          _connectTimeoutMeta,
        ),
      );
    }
    if (data.containsKey('association_timeout')) {
      context.handle(
        _associationTimeoutMeta,
        associationTimeout.isAcceptableOrUnknown(
          data['association_timeout']!,
          _associationTimeoutMeta,
        ),
      );
    }
    if (data.containsKey('dimse_timeout')) {
      context.handle(
        _dimseTimeoutMeta,
        dimseTimeout.isAcceptableOrUnknown(
          data['dimse_timeout']!,
          _dimseTimeoutMeta,
        ),
      );
    }
    if (data.containsKey('idle_timeout')) {
      context.handle(
        _idleTimeoutMeta,
        idleTimeout.isAcceptableOrUnknown(
          data['idle_timeout']!,
          _idleTimeoutMeta,
        ),
      );
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
      connectTimeout: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}connect_timeout'],
      )!,
      associationTimeout: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}association_timeout'],
      )!,
      dimseTimeout: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dimse_timeout'],
      )!,
      idleTimeout: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}idle_timeout'],
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
  final int connectTimeout;
  final int associationTimeout;
  final int dimseTimeout;
  final int idleTimeout;
  final String? selectedNodeId;
  const AppSetting({
    required this.id,
    required this.callingAe,
    required this.listenPort,
    required this.appearance,
    required this.revision,
    required this.connectTimeout,
    required this.associationTimeout,
    required this.dimseTimeout,
    required this.idleTimeout,
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
    map['connect_timeout'] = Variable<int>(connectTimeout);
    map['association_timeout'] = Variable<int>(associationTimeout);
    map['dimse_timeout'] = Variable<int>(dimseTimeout);
    map['idle_timeout'] = Variable<int>(idleTimeout);
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
      connectTimeout: Value(connectTimeout),
      associationTimeout: Value(associationTimeout),
      dimseTimeout: Value(dimseTimeout),
      idleTimeout: Value(idleTimeout),
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
      connectTimeout: serializer.fromJson<int>(json['connectTimeout']),
      associationTimeout: serializer.fromJson<int>(json['associationTimeout']),
      dimseTimeout: serializer.fromJson<int>(json['dimseTimeout']),
      idleTimeout: serializer.fromJson<int>(json['idleTimeout']),
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
      'connectTimeout': serializer.toJson<int>(connectTimeout),
      'associationTimeout': serializer.toJson<int>(associationTimeout),
      'dimseTimeout': serializer.toJson<int>(dimseTimeout),
      'idleTimeout': serializer.toJson<int>(idleTimeout),
      'selectedNodeId': serializer.toJson<String?>(selectedNodeId),
    };
  }

  AppSetting copyWith({
    int? id,
    String? callingAe,
    int? listenPort,
    String? appearance,
    int? revision,
    int? connectTimeout,
    int? associationTimeout,
    int? dimseTimeout,
    int? idleTimeout,
    Value<String?> selectedNodeId = const Value.absent(),
  }) => AppSetting(
    id: id ?? this.id,
    callingAe: callingAe ?? this.callingAe,
    listenPort: listenPort ?? this.listenPort,
    appearance: appearance ?? this.appearance,
    revision: revision ?? this.revision,
    connectTimeout: connectTimeout ?? this.connectTimeout,
    associationTimeout: associationTimeout ?? this.associationTimeout,
    dimseTimeout: dimseTimeout ?? this.dimseTimeout,
    idleTimeout: idleTimeout ?? this.idleTimeout,
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
      connectTimeout: data.connectTimeout.present
          ? data.connectTimeout.value
          : this.connectTimeout,
      associationTimeout: data.associationTimeout.present
          ? data.associationTimeout.value
          : this.associationTimeout,
      dimseTimeout: data.dimseTimeout.present
          ? data.dimseTimeout.value
          : this.dimseTimeout,
      idleTimeout: data.idleTimeout.present
          ? data.idleTimeout.value
          : this.idleTimeout,
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
          ..write('connectTimeout: $connectTimeout, ')
          ..write('associationTimeout: $associationTimeout, ')
          ..write('dimseTimeout: $dimseTimeout, ')
          ..write('idleTimeout: $idleTimeout, ')
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
    connectTimeout,
    associationTimeout,
    dimseTimeout,
    idleTimeout,
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
          other.connectTimeout == this.connectTimeout &&
          other.associationTimeout == this.associationTimeout &&
          other.dimseTimeout == this.dimseTimeout &&
          other.idleTimeout == this.idleTimeout &&
          other.selectedNodeId == this.selectedNodeId);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> id;
  final Value<String> callingAe;
  final Value<int> listenPort;
  final Value<String> appearance;
  final Value<int> revision;
  final Value<int> connectTimeout;
  final Value<int> associationTimeout;
  final Value<int> dimseTimeout;
  final Value<int> idleTimeout;
  final Value<String?> selectedNodeId;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.callingAe = const Value.absent(),
    this.listenPort = const Value.absent(),
    this.appearance = const Value.absent(),
    this.revision = const Value.absent(),
    this.connectTimeout = const Value.absent(),
    this.associationTimeout = const Value.absent(),
    this.dimseTimeout = const Value.absent(),
    this.idleTimeout = const Value.absent(),
    this.selectedNodeId = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    required String callingAe,
    required int listenPort,
    required String appearance,
    required int revision,
    this.connectTimeout = const Value.absent(),
    this.associationTimeout = const Value.absent(),
    this.dimseTimeout = const Value.absent(),
    this.idleTimeout = const Value.absent(),
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
    Expression<int>? connectTimeout,
    Expression<int>? associationTimeout,
    Expression<int>? dimseTimeout,
    Expression<int>? idleTimeout,
    Expression<String>? selectedNodeId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (callingAe != null) 'calling_ae': callingAe,
      if (listenPort != null) 'listen_port': listenPort,
      if (appearance != null) 'appearance': appearance,
      if (revision != null) 'revision': revision,
      if (connectTimeout != null) 'connect_timeout': connectTimeout,
      if (associationTimeout != null) 'association_timeout': associationTimeout,
      if (dimseTimeout != null) 'dimse_timeout': dimseTimeout,
      if (idleTimeout != null) 'idle_timeout': idleTimeout,
      if (selectedNodeId != null) 'selected_node_id': selectedNodeId,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? callingAe,
    Value<int>? listenPort,
    Value<String>? appearance,
    Value<int>? revision,
    Value<int>? connectTimeout,
    Value<int>? associationTimeout,
    Value<int>? dimseTimeout,
    Value<int>? idleTimeout,
    Value<String?>? selectedNodeId,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      callingAe: callingAe ?? this.callingAe,
      listenPort: listenPort ?? this.listenPort,
      appearance: appearance ?? this.appearance,
      revision: revision ?? this.revision,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      associationTimeout: associationTimeout ?? this.associationTimeout,
      dimseTimeout: dimseTimeout ?? this.dimseTimeout,
      idleTimeout: idleTimeout ?? this.idleTimeout,
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
    if (connectTimeout.present) {
      map['connect_timeout'] = Variable<int>(connectTimeout.value);
    }
    if (associationTimeout.present) {
      map['association_timeout'] = Variable<int>(associationTimeout.value);
    }
    if (dimseTimeout.present) {
      map['dimse_timeout'] = Variable<int>(dimseTimeout.value);
    }
    if (idleTimeout.present) {
      map['idle_timeout'] = Variable<int>(idleTimeout.value);
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
          ..write('connectTimeout: $connectTimeout, ')
          ..write('associationTimeout: $associationTimeout, ')
          ..write('dimseTimeout: $dimseTimeout, ')
          ..write('idleTimeout: $idleTimeout, ')
          ..write('selectedNodeId: $selectedNodeId')
          ..write(')'))
        .toString();
  }
}

class $RunsTable extends Runs with TableInfo<$RunsTable, Run> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RunsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES nodes (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _startedMeta = const VerificationMeta(
    'started',
  );
  @override
  late final GeneratedColumn<int> started = GeneratedColumn<int>(
    'started',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedMeta = const VerificationMeta('ended');
  @override
  late final GeneratedColumn<int> ended = GeneratedColumn<int>(
    'ended',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _omittedMeta = const VerificationMeta(
    'omitted',
  );
  @override
  late final GeneratedColumn<int> omitted = GeneratedColumn<int>(
    'omitted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nodeId,
    started,
    ended,
    summary,
    omitted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'runs';
  @override
  VerificationContext validateIntegrity(
    Insertable<Run> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    }
    if (data.containsKey('started')) {
      context.handle(
        _startedMeta,
        started.isAcceptableOrUnknown(data['started']!, _startedMeta),
      );
    } else if (isInserting) {
      context.missing(_startedMeta);
    }
    if (data.containsKey('ended')) {
      context.handle(
        _endedMeta,
        ended.isAcceptableOrUnknown(data['ended']!, _endedMeta),
      );
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    } else if (isInserting) {
      context.missing(_summaryMeta);
    }
    if (data.containsKey('omitted')) {
      context.handle(
        _omittedMeta,
        omitted.isAcceptableOrUnknown(data['omitted']!, _omittedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Run map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Run(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      ),
      started: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started'],
      )!,
      ended: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ended'],
      ),
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
      omitted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}omitted'],
      )!,
    );
  }

  @override
  $RunsTable createAlias(String alias) {
    return $RunsTable(attachedDatabase, alias);
  }
}

class Run extends DataClass implements Insertable<Run> {
  final String id;
  final String? nodeId;
  final int started;
  final int? ended;
  final String summary;
  final int omitted;
  const Run({
    required this.id,
    this.nodeId,
    required this.started,
    this.ended,
    required this.summary,
    required this.omitted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || nodeId != null) {
      map['node_id'] = Variable<String>(nodeId);
    }
    map['started'] = Variable<int>(started);
    if (!nullToAbsent || ended != null) {
      map['ended'] = Variable<int>(ended);
    }
    map['summary'] = Variable<String>(summary);
    map['omitted'] = Variable<int>(omitted);
    return map;
  }

  RunsCompanion toCompanion(bool nullToAbsent) {
    return RunsCompanion(
      id: Value(id),
      nodeId: nodeId == null && nullToAbsent
          ? const Value.absent()
          : Value(nodeId),
      started: Value(started),
      ended: ended == null && nullToAbsent
          ? const Value.absent()
          : Value(ended),
      summary: Value(summary),
      omitted: Value(omitted),
    );
  }

  factory Run.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Run(
      id: serializer.fromJson<String>(json['id']),
      nodeId: serializer.fromJson<String?>(json['nodeId']),
      started: serializer.fromJson<int>(json['started']),
      ended: serializer.fromJson<int?>(json['ended']),
      summary: serializer.fromJson<String>(json['summary']),
      omitted: serializer.fromJson<int>(json['omitted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nodeId': serializer.toJson<String?>(nodeId),
      'started': serializer.toJson<int>(started),
      'ended': serializer.toJson<int?>(ended),
      'summary': serializer.toJson<String>(summary),
      'omitted': serializer.toJson<int>(omitted),
    };
  }

  Run copyWith({
    String? id,
    Value<String?> nodeId = const Value.absent(),
    int? started,
    Value<int?> ended = const Value.absent(),
    String? summary,
    int? omitted,
  }) => Run(
    id: id ?? this.id,
    nodeId: nodeId.present ? nodeId.value : this.nodeId,
    started: started ?? this.started,
    ended: ended.present ? ended.value : this.ended,
    summary: summary ?? this.summary,
    omitted: omitted ?? this.omitted,
  );
  Run copyWithCompanion(RunsCompanion data) {
    return Run(
      id: data.id.present ? data.id.value : this.id,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      started: data.started.present ? data.started.value : this.started,
      ended: data.ended.present ? data.ended.value : this.ended,
      summary: data.summary.present ? data.summary.value : this.summary,
      omitted: data.omitted.present ? data.omitted.value : this.omitted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Run(')
          ..write('id: $id, ')
          ..write('nodeId: $nodeId, ')
          ..write('started: $started, ')
          ..write('ended: $ended, ')
          ..write('summary: $summary, ')
          ..write('omitted: $omitted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nodeId, started, ended, summary, omitted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Run &&
          other.id == this.id &&
          other.nodeId == this.nodeId &&
          other.started == this.started &&
          other.ended == this.ended &&
          other.summary == this.summary &&
          other.omitted == this.omitted);
}

class RunsCompanion extends UpdateCompanion<Run> {
  final Value<String> id;
  final Value<String?> nodeId;
  final Value<int> started;
  final Value<int?> ended;
  final Value<String> summary;
  final Value<int> omitted;
  final Value<int> rowid;
  const RunsCompanion({
    this.id = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.started = const Value.absent(),
    this.ended = const Value.absent(),
    this.summary = const Value.absent(),
    this.omitted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RunsCompanion.insert({
    required String id,
    this.nodeId = const Value.absent(),
    required int started,
    this.ended = const Value.absent(),
    required String summary,
    this.omitted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       started = Value(started),
       summary = Value(summary);
  static Insertable<Run> custom({
    Expression<String>? id,
    Expression<String>? nodeId,
    Expression<int>? started,
    Expression<int>? ended,
    Expression<String>? summary,
    Expression<int>? omitted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nodeId != null) 'node_id': nodeId,
      if (started != null) 'started': started,
      if (ended != null) 'ended': ended,
      if (summary != null) 'summary': summary,
      if (omitted != null) 'omitted': omitted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RunsCompanion copyWith({
    Value<String>? id,
    Value<String?>? nodeId,
    Value<int>? started,
    Value<int?>? ended,
    Value<String>? summary,
    Value<int>? omitted,
    Value<int>? rowid,
  }) {
    return RunsCompanion(
      id: id ?? this.id,
      nodeId: nodeId ?? this.nodeId,
      started: started ?? this.started,
      ended: ended ?? this.ended,
      summary: summary ?? this.summary,
      omitted: omitted ?? this.omitted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (started.present) {
      map['started'] = Variable<int>(started.value);
    }
    if (ended.present) {
      map['ended'] = Variable<int>(ended.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (omitted.present) {
      map['omitted'] = Variable<int>(omitted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RunsCompanion(')
          ..write('id: $id, ')
          ..write('nodeId: $nodeId, ')
          ..write('started: $started, ')
          ..write('ended: $ended, ')
          ..write('summary: $summary, ')
          ..write('omitted: $omitted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RunEventsTable extends RunEvents
    with TableInfo<$RunEventsTable, RunEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RunEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  @override
  late final GeneratedColumn<String> runId = GeneratedColumn<String>(
    'run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES runs (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
    'sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<int> bytes = GeneratedColumn<int>(
    'bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [runId, sequence, payload, bytes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'run_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<RunEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    } else if (isInserting) {
      context.missing(_sequenceMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('bytes')) {
      context.handle(
        _bytesMeta,
        bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta),
      );
    } else if (isInserting) {
      context.missing(_bytesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {runId, sequence};
  @override
  RunEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RunEvent(
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}run_id'],
      )!,
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      bytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bytes'],
      )!,
    );
  }

  @override
  $RunEventsTable createAlias(String alias) {
    return $RunEventsTable(attachedDatabase, alias);
  }
}

class RunEvent extends DataClass implements Insertable<RunEvent> {
  final String runId;
  final int sequence;
  final String payload;
  final int bytes;
  const RunEvent({
    required this.runId,
    required this.sequence,
    required this.payload,
    required this.bytes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['run_id'] = Variable<String>(runId);
    map['sequence'] = Variable<int>(sequence);
    map['payload'] = Variable<String>(payload);
    map['bytes'] = Variable<int>(bytes);
    return map;
  }

  RunEventsCompanion toCompanion(bool nullToAbsent) {
    return RunEventsCompanion(
      runId: Value(runId),
      sequence: Value(sequence),
      payload: Value(payload),
      bytes: Value(bytes),
    );
  }

  factory RunEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RunEvent(
      runId: serializer.fromJson<String>(json['runId']),
      sequence: serializer.fromJson<int>(json['sequence']),
      payload: serializer.fromJson<String>(json['payload']),
      bytes: serializer.fromJson<int>(json['bytes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'runId': serializer.toJson<String>(runId),
      'sequence': serializer.toJson<int>(sequence),
      'payload': serializer.toJson<String>(payload),
      'bytes': serializer.toJson<int>(bytes),
    };
  }

  RunEvent copyWith({
    String? runId,
    int? sequence,
    String? payload,
    int? bytes,
  }) => RunEvent(
    runId: runId ?? this.runId,
    sequence: sequence ?? this.sequence,
    payload: payload ?? this.payload,
    bytes: bytes ?? this.bytes,
  );
  RunEvent copyWithCompanion(RunEventsCompanion data) {
    return RunEvent(
      runId: data.runId.present ? data.runId.value : this.runId,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      payload: data.payload.present ? data.payload.value : this.payload,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RunEvent(')
          ..write('runId: $runId, ')
          ..write('sequence: $sequence, ')
          ..write('payload: $payload, ')
          ..write('bytes: $bytes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(runId, sequence, payload, bytes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RunEvent &&
          other.runId == this.runId &&
          other.sequence == this.sequence &&
          other.payload == this.payload &&
          other.bytes == this.bytes);
}

class RunEventsCompanion extends UpdateCompanion<RunEvent> {
  final Value<String> runId;
  final Value<int> sequence;
  final Value<String> payload;
  final Value<int> bytes;
  final Value<int> rowid;
  const RunEventsCompanion({
    this.runId = const Value.absent(),
    this.sequence = const Value.absent(),
    this.payload = const Value.absent(),
    this.bytes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RunEventsCompanion.insert({
    required String runId,
    required int sequence,
    required String payload,
    required int bytes,
    this.rowid = const Value.absent(),
  }) : runId = Value(runId),
       sequence = Value(sequence),
       payload = Value(payload),
       bytes = Value(bytes);
  static Insertable<RunEvent> custom({
    Expression<String>? runId,
    Expression<int>? sequence,
    Expression<String>? payload,
    Expression<int>? bytes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (runId != null) 'run_id': runId,
      if (sequence != null) 'sequence': sequence,
      if (payload != null) 'payload': payload,
      if (bytes != null) 'bytes': bytes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RunEventsCompanion copyWith({
    Value<String>? runId,
    Value<int>? sequence,
    Value<String>? payload,
    Value<int>? bytes,
    Value<int>? rowid,
  }) {
    return RunEventsCompanion(
      runId: runId ?? this.runId,
      sequence: sequence ?? this.sequence,
      payload: payload ?? this.payload,
      bytes: bytes ?? this.bytes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (runId.present) {
      map['run_id'] = Variable<String>(runId.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<int>(bytes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RunEventsCompanion(')
          ..write('runId: $runId, ')
          ..write('sequence: $sequence, ')
          ..write('payload: $payload, ')
          ..write('bytes: $bytes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $NodesTable nodes = $NodesTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $RunsTable runs = $RunsTable(this);
  late final $RunEventsTable runEvents = $RunEventsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    nodes,
    appSettings,
    runs,
    runEvents,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'nodes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('runs', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'runs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('run_events', kind: UpdateKind.delete)],
    ),
  ]);
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

  static MultiTypedResultKey<$RunsTable, List<Run>> _runsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.runs,
    aliasName: 'nodes__id__runs__node_id',
  );

  $$RunsTableProcessedTableManager get runsRefs {
    final manager = $$RunsTableTableManager(
      $_db,
      $_db.runs,
    ).filter((f) => f.nodeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_runsRefsTable($_db));
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

  Expression<bool> runsRefs(
    Expression<bool> Function($$RunsTableFilterComposer f) f,
  ) {
    final $$RunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.runs,
      getReferencedColumn: (t) => t.nodeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RunsTableFilterComposer(
            $db: $db,
            $table: $db.runs,
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

  Expression<T> runsRefs<T extends Object>(
    Expression<T> Function($$RunsTableAnnotationComposer a) f,
  ) {
    final $$RunsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.runs,
      getReferencedColumn: (t) => t.nodeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RunsTableAnnotationComposer(
            $db: $db,
            $table: $db.runs,
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
          PrefetchHooks Function({bool appSettingsRefs, bool runsRefs})
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
          prefetchHooksCallback: ({appSettingsRefs = false, runsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (appSettingsRefs) db.appSettings,
                if (runsRefs) db.runs,
              ],
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
                  if (runsRefs)
                    await $_getPrefetchedData<Node, $NodesTable, Run>(
                      currentTable: table,
                      referencedTable: $$NodesTableReferences._runsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$NodesTableReferences(db, table, p0).runsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.nodeId == item.id),
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
      PrefetchHooks Function({bool appSettingsRefs, bool runsRefs})
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      required String callingAe,
      required int listenPort,
      required String appearance,
      required int revision,
      Value<int> connectTimeout,
      Value<int> associationTimeout,
      Value<int> dimseTimeout,
      Value<int> idleTimeout,
      Value<String?> selectedNodeId,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String> callingAe,
      Value<int> listenPort,
      Value<String> appearance,
      Value<int> revision,
      Value<int> connectTimeout,
      Value<int> associationTimeout,
      Value<int> dimseTimeout,
      Value<int> idleTimeout,
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

  ColumnFilters<int> get connectTimeout => $composableBuilder(
    column: $table.connectTimeout,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get associationTimeout => $composableBuilder(
    column: $table.associationTimeout,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dimseTimeout => $composableBuilder(
    column: $table.dimseTimeout,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get idleTimeout => $composableBuilder(
    column: $table.idleTimeout,
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

  ColumnOrderings<int> get connectTimeout => $composableBuilder(
    column: $table.connectTimeout,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get associationTimeout => $composableBuilder(
    column: $table.associationTimeout,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dimseTimeout => $composableBuilder(
    column: $table.dimseTimeout,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get idleTimeout => $composableBuilder(
    column: $table.idleTimeout,
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

  GeneratedColumn<int> get connectTimeout => $composableBuilder(
    column: $table.connectTimeout,
    builder: (column) => column,
  );

  GeneratedColumn<int> get associationTimeout => $composableBuilder(
    column: $table.associationTimeout,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dimseTimeout => $composableBuilder(
    column: $table.dimseTimeout,
    builder: (column) => column,
  );

  GeneratedColumn<int> get idleTimeout => $composableBuilder(
    column: $table.idleTimeout,
    builder: (column) => column,
  );

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
                Value<int> connectTimeout = const Value.absent(),
                Value<int> associationTimeout = const Value.absent(),
                Value<int> dimseTimeout = const Value.absent(),
                Value<int> idleTimeout = const Value.absent(),
                Value<String?> selectedNodeId = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                callingAe: callingAe,
                listenPort: listenPort,
                appearance: appearance,
                revision: revision,
                connectTimeout: connectTimeout,
                associationTimeout: associationTimeout,
                dimseTimeout: dimseTimeout,
                idleTimeout: idleTimeout,
                selectedNodeId: selectedNodeId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String callingAe,
                required int listenPort,
                required String appearance,
                required int revision,
                Value<int> connectTimeout = const Value.absent(),
                Value<int> associationTimeout = const Value.absent(),
                Value<int> dimseTimeout = const Value.absent(),
                Value<int> idleTimeout = const Value.absent(),
                Value<String?> selectedNodeId = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                callingAe: callingAe,
                listenPort: listenPort,
                appearance: appearance,
                revision: revision,
                connectTimeout: connectTimeout,
                associationTimeout: associationTimeout,
                dimseTimeout: dimseTimeout,
                idleTimeout: idleTimeout,
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
typedef $$RunsTableCreateCompanionBuilder = RunsCompanion Function({
  required String id,
  Value<String?> nodeId,
  required int started,
  Value<int?> ended,
  required String summary,
  Value<int> omitted,
  Value<int> rowid,
});
typedef $$RunsTableUpdateCompanionBuilder = RunsCompanion Function({
  Value<String> id,
  Value<String?> nodeId,
  Value<int> started,
  Value<int?> ended,
  Value<String> summary,
  Value<int> omitted,
  Value<int> rowid,
});

final class $$RunsTableReferences
    extends BaseReferences<_$AppDatabase, $RunsTable, Run> {
  $$RunsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $NodesTable _nodeIdTable(_$AppDatabase db) =>
      db.nodes.createAlias('runs__node_id__nodes__id');

  $$NodesTableProcessedTableManager? get nodeId {
    final $_column = $_itemColumn<String>('node_id');
    if ($_column == null) return null;
    final manager = $$NodesTableTableManager(
      $_db,
      $_db.nodes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_nodeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$RunEventsTable, List<RunEvent>>
  _runEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.runEvents,
    aliasName: 'runs__id__run_events__run_id',
  );

  $$RunEventsTableProcessedTableManager get runEventsRefs {
    final manager = $$RunEventsTableTableManager(
      $_db,
      $_db.runEvents,
    ).filter((f) => f.runId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_runEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RunsTableFilterComposer extends Composer<_$AppDatabase, $RunsTable> {
  $$RunsTableFilterComposer({
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

  ColumnFilters<int> get started => $composableBuilder(
    column: $table.started,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ended => $composableBuilder(
    column: $table.ended,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get omitted => $composableBuilder(
    column: $table.omitted,
    builder: (column) => ColumnFilters(column),
  );

  $$NodesTableFilterComposer get nodeId {
    final $$NodesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nodeId,
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

  Expression<bool> runEventsRefs(
    Expression<bool> Function($$RunEventsTableFilterComposer f) f,
  ) {
    final $$RunEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.runEvents,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RunEventsTableFilterComposer(
            $db: $db,
            $table: $db.runEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RunsTableOrderingComposer extends Composer<_$AppDatabase, $RunsTable> {
  $$RunsTableOrderingComposer({
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

  ColumnOrderings<int> get started => $composableBuilder(
    column: $table.started,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ended => $composableBuilder(
    column: $table.ended,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get omitted => $composableBuilder(
    column: $table.omitted,
    builder: (column) => ColumnOrderings(column),
  );

  $$NodesTableOrderingComposer get nodeId {
    final $$NodesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nodeId,
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

class $$RunsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RunsTable> {
  $$RunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get started =>
      $composableBuilder(column: $table.started, builder: (column) => column);

  GeneratedColumn<int> get ended =>
      $composableBuilder(column: $table.ended, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<int> get omitted =>
      $composableBuilder(column: $table.omitted, builder: (column) => column);

  $$NodesTableAnnotationComposer get nodeId {
    final $$NodesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nodeId,
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

  Expression<T> runEventsRefs<T extends Object>(
    Expression<T> Function($$RunEventsTableAnnotationComposer a) f,
  ) {
    final $$RunEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.runEvents,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RunEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.runEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RunsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RunsTable,
          Run,
          $$RunsTableFilterComposer,
          $$RunsTableOrderingComposer,
          $$RunsTableAnnotationComposer,
          $$RunsTableCreateCompanionBuilder,
          $$RunsTableUpdateCompanionBuilder,
          (Run, $$RunsTableReferences),
          Run,
          PrefetchHooks Function({bool nodeId, bool runEventsRefs})
        > {
  $$RunsTableTableManager(_$AppDatabase db, $RunsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> nodeId = const Value.absent(),
                Value<int> started = const Value.absent(),
                Value<int?> ended = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<int> omitted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RunsCompanion(
                id: id,
                nodeId: nodeId,
                started: started,
                ended: ended,
                summary: summary,
                omitted: omitted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> nodeId = const Value.absent(),
                required int started,
                Value<int?> ended = const Value.absent(),
                required String summary,
                Value<int> omitted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RunsCompanion.insert(
                id: id,
                nodeId: nodeId,
                started: started,
                ended: ended,
                summary: summary,
                omitted: omitted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RunsTable, Run>(table),
                  $$RunsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({nodeId = false, runEventsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (runEventsRefs) db.runEvents],
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
                    if (nodeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.nodeId,
                        referencedTable: $$RunsTableReferences._nodeIdTable(db),
                        referencedColumn: $$RunsTableReferences
                            ._nodeIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (runEventsRefs)
                    await $_getPrefetchedData<Run, $RunsTable, RunEvent>(
                      currentTable: table,
                      referencedTable: $$RunsTableReferences
                          ._runEventsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$RunsTableReferences(db, table, p0).runEventsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.runId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RunsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RunsTable,
      Run,
      $$RunsTableFilterComposer,
      $$RunsTableOrderingComposer,
      $$RunsTableAnnotationComposer,
      $$RunsTableCreateCompanionBuilder,
      $$RunsTableUpdateCompanionBuilder,
      (Run, $$RunsTableReferences),
      Run,
      PrefetchHooks Function({bool nodeId, bool runEventsRefs})
    >;
typedef $$RunEventsTableCreateCompanionBuilder = RunEventsCompanion Function({
  required String runId,
  required int sequence,
  required String payload,
  required int bytes,
  Value<int> rowid,
});
typedef $$RunEventsTableUpdateCompanionBuilder = RunEventsCompanion Function({
  Value<String> runId,
  Value<int> sequence,
  Value<String> payload,
  Value<int> bytes,
  Value<int> rowid,
});

final class $$RunEventsTableReferences
    extends BaseReferences<_$AppDatabase, $RunEventsTable, RunEvent> {
  $$RunEventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RunsTable _runIdTable(_$AppDatabase db) =>
      db.runs.createAlias('run_events__run_id__runs__id');

  $$RunsTableProcessedTableManager get runId {
    final $_column = $_itemColumn<String>('run_id')!;

    final manager = $$RunsTableTableManager(
      $_db,
      $_db.runs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_runIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RunEventsTableFilterComposer
    extends Composer<_$AppDatabase, $RunEventsTable> {
  $$RunEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnFilters(column),
  );

  $$RunsTableFilterComposer get runId {
    final $$RunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.runs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RunsTableFilterComposer(
            $db: $db,
            $table: $db.runs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RunEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $RunEventsTable> {
  $$RunEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnOrderings(column),
  );

  $$RunsTableOrderingComposer get runId {
    final $$RunsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.runs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RunsTableOrderingComposer(
            $db: $db,
            $table: $db.runs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RunEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RunEventsTable> {
  $$RunEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => column);

  $$RunsTableAnnotationComposer get runId {
    final $$RunsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.runs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RunsTableAnnotationComposer(
            $db: $db,
            $table: $db.runs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RunEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RunEventsTable,
          RunEvent,
          $$RunEventsTableFilterComposer,
          $$RunEventsTableOrderingComposer,
          $$RunEventsTableAnnotationComposer,
          $$RunEventsTableCreateCompanionBuilder,
          $$RunEventsTableUpdateCompanionBuilder,
          (RunEvent, $$RunEventsTableReferences),
          RunEvent,
          PrefetchHooks Function({bool runId})
        > {
  $$RunEventsTableTableManager(_$AppDatabase db, $RunEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RunEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RunEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RunEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> runId = const Value.absent(),
                Value<int> sequence = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> bytes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RunEventsCompanion(
                runId: runId,
                sequence: sequence,
                payload: payload,
                bytes: bytes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String runId,
                required int sequence,
                required String payload,
                required int bytes,
                Value<int> rowid = const Value.absent(),
              }) => RunEventsCompanion.insert(
                runId: runId,
                sequence: sequence,
                payload: payload,
                bytes: bytes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RunEventsTable, RunEvent>(table),
                  $$RunEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({runId = false}) {
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
                    if (runId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.runId,
                        referencedTable: $$RunEventsTableReferences._runIdTable(
                          db,
                        ),
                        referencedColumn: $$RunEventsTableReferences
                            ._runIdTable(db)
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

typedef $$RunEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RunEventsTable,
      RunEvent,
      $$RunEventsTableFilterComposer,
      $$RunEventsTableOrderingComposer,
      $$RunEventsTableAnnotationComposer,
      $$RunEventsTableCreateCompanionBuilder,
      $$RunEventsTableUpdateCompanionBuilder,
      (RunEvent, $$RunEventsTableReferences),
      RunEvent,
      PrefetchHooks Function({bool runId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$NodesTableTableManager get nodes =>
      $$NodesTableTableManager(_db, _db.nodes);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$RunsTableTableManager get runs => $$RunsTableTableManager(_db, _db.runs);
  $$RunEventsTableTableManager get runEvents =>
      $$RunEventsTableTableManager(_db, _db.runEvents);
}
