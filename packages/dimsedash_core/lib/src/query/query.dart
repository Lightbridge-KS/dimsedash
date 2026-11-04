import 'dart:convert';

import 'package:dartdicom/dartdicom.dart';

import '../configuration/configuration.dart';

const findSessionByteLimit = 32 * 1024 * 1024;
const findIdentifierByteLimit = 1024 * 1024;

enum FindLevel { study, series, image }

enum FindKey { patientId, patientName, accession, date, modality, bodyPart }

enum FindPurpose { match, returnKey }

enum FindDisposition { complete, limited, cancelled, failed, stopped }

enum FindFailure {
  connection,
  associationRejected,
  contextRejected,
  timeout,
  peerAbort,
  transport,
  protocol,
  identifierTooLarge,
  unexpected,
}

final class FindEntry {
  const FindEntry({
    this.value = '',
    this.enabled = true,
    this.purpose = FindPurpose.returnKey,
  });
  final String value;
  final bool enabled;
  final FindPurpose purpose;
  FindEntry copy({String? value, bool? enabled, FindPurpose? purpose}) =>
      FindEntry(
        value: value ?? this.value,
        enabled: enabled ?? this.enabled,
        purpose: purpose ?? this.purpose,
      );
}

/// Immutable editing intent. Only the common-key authoring surface is in S2A.
final class FindIdentifier {
  FindIdentifier({
    this.level = FindLevel.study,
    this.studyUid,
    this.seriesUid,
    this.rowLimit = 1000,
    Map<FindKey, FindEntry> entries = const {},
  }) : entries = Map.unmodifiable(entries);
  final FindLevel level;
  final String? studyUid, seriesUid;
  final int rowLimit;
  final Map<FindKey, FindEntry> entries;
  FindEntry entry(FindKey key) => entries[key] ?? const FindEntry();
  FindIdentifier copy({FindKey? key, FindEntry? value, int? rowLimit}) =>
      FindIdentifier(
        level: level,
        studyUid: studyUid,
        seriesUid: seriesUid,
        rowLimit: rowLimit ?? this.rowLimit,
        entries: {...entries, if (key != null && value != null) key: value},
      );
  List<FindKey> get keys => switch (level) {
    FindLevel.study => [
      FindKey.patientId,
      FindKey.patientName,
      FindKey.accession,
      FindKey.date,
      FindKey.modality,
    ],
    FindLevel.series => [FindKey.modality, FindKey.bodyPart],
    FindLevel.image => [],
  };
  String? get validation {
    if (rowLimit < 1 || rowLimit > 10000) {
      return 'Result limit must be from 1 to 10,000.';
    }
    if (level != FindLevel.study && !validQueryUid(studyUid)) {
      return 'A valid parent Study Instance UID is required.';
    }
    if (level == FindLevel.image && !validQueryUid(seriesUid)) {
      return 'A valid parent Series Instance UID is required.';
    }
    for (final key in keys) {
      final e = entry(key);
      if (!e.enabled || e.purpose == FindPurpose.returnKey) continue;
      final name = findKeyName(key, level);
      if (e.value.isEmpty) {
        return '$name needs a matching value. Choose Return or disable it.';
      }
      if (e.value.contains(RegExp(r'[\x00-\x1f\x7f\\]'))) {
        return '$name cannot contain control characters or multiple values.';
      }
      if (key == FindKey.date) {
        final parts = e.value.split('-');
        if (parts.length > 2 ||
            parts.every((p) => p.isEmpty) ||
            parts.any((p) => p.isNotEmpty && !validQueryDate(p))) {
          return 'Use valid dates (YYYY-MM-DD), or a DA date/range in Advanced.';
        }
        if (parts.length == 2 &&
            parts.every((p) => p.isNotEmpty) &&
            parts[0].compareTo(parts[1]) > 0) {
          return 'Study date From must not be later than Through.';
        }
      } else {
        final max =
            key == FindKey.accession ||
                key == FindKey.modality ||
                key == FindKey.bodyPart
            ? 16
            : 64;
        final components = key == FindKey.patientName
            ? e.value.split('=')
            : [e.value];
        if (components.any((v) => v.runes.length > max) ||
            (key == FindKey.patientName && components.length > 3)) {
          return '$name exceeds its supported VR length.';
        }
        if ((key == FindKey.modality || key == FindKey.bodyPart) &&
            !RegExp(r'^[A-Z0-9 _*?]+$').hasMatch(e.value)) {
          return '$name uses uppercase CS values (letters, digits, space, underscore or explicit wildcards).';
        }
      }
    }
    return null;
  }

  List<FindElement> get elements {
    final result = <FindElement>[
      FindElement(0x00080052, 'CS', level.name.toUpperCase(), required: true),
    ];
    if (level != FindLevel.study) {
      result.add(FindElement(0x0020000D, 'UI', studyUid ?? '', required: true));
    }
    if (level == FindLevel.image) {
      result.add(
        FindElement(0x0020000E, 'UI', seriesUid ?? '', required: true),
      );
    }
    for (final key in keys) {
      final e = entry(key);
      if (e.enabled) {
        result.add(
          FindElement(
            findKeyTag(key, level),
            findKeyVr(key),
            e.purpose == FindPurpose.match ? e.value : '',
          ),
        );
      }
    }
    result.addAll(switch (level) {
      FindLevel.study => [
        const FindElement(0x0020000D, 'UI', '', required: true),
        const FindElement(0x00081030, 'LO', ''),
        const FindElement(0x00201206, 'IS', ''),
      ],
      FindLevel.series => [
        const FindElement(0x0020000E, 'UI', '', required: true),
        const FindElement(0x0008103E, 'LO', ''),
        const FindElement(0x00201209, 'IS', ''),
      ],
      FindLevel.image => [
        const FindElement(0x00080018, 'UI', '', required: true),
        const FindElement(0x00200013, 'IS', ''),
      ],
    });
    if (result.any((e) => e.value.runes.any((r) => r > 127))) {
      result.add(
        const FindElement(0x00080005, 'CS', 'ISO_IR 192', required: true),
      );
    }
    return List.unmodifiable(result);
  }

  String get resolved => elements
      .map(
        (e) =>
            '${e.tagText} ${e.vr} ${e.keyword} = ${e.value.isEmpty ? '<empty · return key>' : e.value}',
      )
      .join('\n');
}

final class FindElement {
  const FindElement(this.tag, this.vr, this.value, {this.required = false});
  final int tag;
  final String vr, value;
  final bool required;
  String get keyword =>
      Dictionary.standard.entry(Tag(tag))?.keyword ?? 'Unknown';
  String get tagText =>
      '(${(tag >> 16).toRadixString(16).padLeft(4, '0')},${(tag & 65535).toRadixString(16).padLeft(4, '0')})'
          .toUpperCase();
}

String findKeyName(FindKey key, FindLevel level) =>
    FindElement(findKeyTag(key, level), findKeyVr(key), '').keyword;
int findKeyTag(FindKey key, FindLevel level) => switch (key) {
  FindKey.patientId => 0x00100020,
  FindKey.patientName => 0x00100010,
  FindKey.accession => 0x00080050,
  FindKey.date => 0x00080020,
  FindKey.modality => level == FindLevel.study ? 0x00080061 : 0x00080060,
  FindKey.bodyPart => 0x00180015,
};
String findKeyVr(FindKey key) => switch (key) {
  FindKey.patientId => 'LO',
  FindKey.patientName => 'PN',
  FindKey.accession => 'SH',
  FindKey.date => 'DA',
  FindKey.modality || FindKey.bodyPart => 'CS',
};
bool validQueryUid(String? value) =>
    value != null &&
    value.length <= 64 &&
    RegExp(r'^(0|[1-9][0-9]*)(\.(0|[1-9][0-9]*))+$').hasMatch(value);
bool validQueryDate(String value) {
  if (!RegExp(r'^\d{8}$').hasMatch(value)) return false;
  final y = int.parse(value.substring(0, 4)),
      m = int.parse(value.substring(4, 6)),
      d = int.parse(value.substring(6));
  final date = DateTime(y, m, d);
  return y > 0 && date.year == y && date.month == m && date.day == d;
}

final class ResolvedFindRequest {
  const ResolvedFindRequest({
    required this.node,
    required this.client,
    required this.configurationRevision,
    required this.identifier,
  });
  final PacsNode node;
  final ClientSettings client;
  final int configurationRevision;
  final FindIdentifier identifier;
  bool settingsDiffer(AppConfiguration c) =>
      c.node?.id != node.id ||
      c.node?.revision != node.revision ||
      c.client.callingAe != client.callingAe ||
      client.timeouts.values.entries.any(
        (e) => c.client.timeouts.values[e.key] != e.value,
      );
  bool targetChanged(AppConfiguration c) =>
      c.node?.id != node.id ||
      c.node?.revision != node.revision ||
      c.client.callingAe != client.callingAe;
}

/// Read-owned metadata projection; no mutable SDK datasets escape the adapter.
final class QueryAttribute {
  QueryAttribute({
    required this.tag,
    required this.keyword,
    required this.vr,
    Iterable<String> values = const [],
    Iterable<Iterable<QueryAttribute>> items = const [],
    this.decodeLimited = false,
  }) : values = List.unmodifiable(values),
       items = List.unmodifiable(
         items.map((i) => List<QueryAttribute>.unmodifiable(i)),
       );
  final int tag;
  final String keyword, vr;
  final List<String> values;
  final List<List<QueryAttribute>> items;
  final bool decodeLimited;
  String get text => values.join('\\');
  int get accountedBytes =>
      32 +
      utf8.encode(keyword + vr + text).length +
      items.fold(
        0,
        (n, item) => n + item.fold(0, (n, a) => n + a.accountedBytes),
      );
}

final class QueryMatch {
  QueryMatch({
    required this.ordinal,
    required this.encodedBytes,
    required Iterable<QueryAttribute> attributes,
    this.optionalKeysUnsupported = false,
  }) : attributes = List.unmodifiable(attributes);
  final int ordinal, encodedBytes;
  final List<QueryAttribute> attributes;
  final bool optionalKeysUnsupported;
  QueryAttribute? attribute(int tag) =>
      attributes.where((a) => a.tag == tag).firstOrNull;
  String? value(int tag) => attribute(tag)?.text;
  String? get studyUid => value(0x0020000D);
  String? get seriesUid => value(0x0020000E);
  String? get sopUid => value(0x00080018);
  int get accountedBytes =>
      encodedBytes + attributes.fold(0, (n, a) => n + a.accountedBytes);
  String? targetProblem(FindIdentifier id) {
    if (!validQueryUid(studyUid) ||
        (id.level != FindLevel.study && !validQueryUid(seriesUid)) ||
        (id.level == FindLevel.image && !validQueryUid(sopUid))) {
      return 'Required UID missing or invalid.';
    }
    if ((id.studyUid != null && id.studyUid != studyUid) ||
        (id.seriesUid != null && id.seriesUid != seriesUid)) {
      return 'Returned UID conflicts with the requested parent.';
    }
    return null;
  }
}

final class FindOutcome {
  const FindOutcome({
    required this.disposition,
    this.status,
    this.failure,
    this.cancelRequested = false,
    this.cancellationConfirmed = false,
    this.optionalKeysUnsupported = false,
    this.cleanupFailed = false,
    this.responses = 0,
  });
  final FindDisposition disposition;
  final int? status;
  final FindFailure? failure;
  final bool cancelRequested,
      cancellationConfirmed,
      optionalKeysUnsupported,
      cleanupFailed;
  final int responses;
}

final class QueryResultContext {
  QueryResultContext({
    required this.runId,
    required this.request,
    required Iterable<QueryMatch> rows,
    this.outcome,
    this.active = false,
    this.limitReached = false,
    this.received = 0,
    this.accountedBytes = 0,
  }) : rows = List.unmodifiable(rows);
  final String runId;
  final ResolvedFindRequest request;
  final List<QueryMatch> rows;
  final FindOutcome? outcome;
  final bool active, limitReached;
  final int received, accountedBytes;
}
