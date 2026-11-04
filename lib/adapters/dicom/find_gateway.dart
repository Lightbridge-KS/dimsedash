import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartdicom/dartdicom.dart' as dicom;
import 'package:dartdicom_net/dartdicom_net.dart' as net;
import 'package:dimsedash_core/dimsedash_core.dart';

import 'observations.dart';

/// Every execution receives a fresh private SDK dataset.
dicom.Dataset materializeFind(FindIdentifier id) {
  final dataset = dicom.Dataset();
  for (final element in id.elements) {
    final tag = dicom.Tag(element.tag);
    if (element.value.isEmpty) {
      dataset.setEmpty(tag);
    } else {
      dataset.setRaw(tag, dicom.Vr.fromCode(element.vr)!, [element.value]);
    }
  }
  return dataset;
}

String? validateFindEncoding(FindIdentifier identifier) {
  try {
    materializeFind(identifier)
        .toBytes(transferSyntax: dicom.TransferSyntaxes.explicitVrLittleEndian);
    return null;
  } on dicom.DicomException {
    return 'Identifier cannot be encoded. Review its values and character set.';
  } on ArgumentError {
    return 'Identifier has an invalid VR or value.';
  }
}

final class DartDicomFindRun
    implements FindGatewayRun, net.AssociationObserver {
  DartDicomFindRun(this.id, this.request, this.observe, this.match) {
    done = _execute();
  }
  final String id;
  final ResolvedFindRequest request;
  final void Function(EchoObservation) observe;
  final void Function(QueryMatch) match;
  final _establishment = net.AssociationCancellation();
  net.Association? _association;
  net.FindOperation? _find;
  bool _cancelled = false;
  @override
  late final Future<FindOutcome> done;
  @override
  void record(net.AssociationObservation event) =>
      observe(projectObservation(event));
  @override
  void cancel() {
    _cancelled = true;
    if (_find != null) {
      unawaited(_find!.cancel());
    } else {
      _establishment.cancel();
    }
  }

  @override
  void forceClose() {
    _establishment.cancel();
    _association?.forceClose();
  }

  Future<FindOutcome> _execute() async {
    net.FindCompletion? terminal;
    FindFailure? failure;
    bool cleanupFailed = false;
    StreamSubscription<net.FindMatch>? subscription;
    int ordinal = 0;
    bool projectionFailed = false;
    try {
      final t = request.client.timeouts;
      _association =
          await net.ApplicationEntity(
            aeTitle: request.client.callingAe,
            requestedContexts: [
              const net.PresentationContext(
                dicom.SopClasses.studyRootQueryRetrieveInformationModelFind,
              ),
            ],
            observer: this,
            timeouts: net.Timeouts(
              connect: Duration(seconds: t.connect),
              acse: Duration(seconds: t.association),
              dimse: Duration(seconds: t.dimse),
              network: Duration(seconds: t.idle),
            ),
          ).associate(
            request.node.host,
            request.node.port,
            aeTitle: request.node.calledAe,
            cancellation: _establishment,
            associationId: id,
          );
      if (!_association!.acceptedContexts.any(
        (c) =>
            c.abstractSyntax ==
                dicom.SopClasses.studyRootQueryRetrieveInformationModelFind &&
            c.scuRole,
      )) {
        failure = FindFailure.contextRejected;
      } else if (!_cancelled) {
        _find = _association!.startCFind(
          materializeFind(request.identifier),
          maxIdentifierBytes: findIdentifierByteLimit,
        );
        subscription = _find!.matches.listen((value) {
          try {
            match(
              QueryMatch(
                ordinal: ++ordinal,
                encodedBytes: value.encodedBytes,
                attributes: projectQueryMetadata(value.dataset),
                optionalKeysUnsupported: value.status.code == 0xFF01,
              ),
            );
          } catch (_) {
            projectionFailed = true;
            cancel();
          }
        });
        terminal = await _find!.done;
        failure = projectionFailed
            ? FindFailure.protocol
            : _mapFailure(terminal.failure);
      }
      try {
        await _association!.release();
      } catch (_) {
        cleanupFailed = true;
      }
    } on net.DimseException catch (e) {
      failure = _mapFailure(e);
    } on SocketException {
      failure = FindFailure.connection;
    } catch (_) {
      failure = FindFailure.unexpected;
    } finally {
      await subscription?.cancel();
      if (_association != null) {
        try {
          await _association!.abort().timeout(const Duration(seconds: 2));
          await _association!.closed.timeout(const Duration(seconds: 2));
        } catch (_) {
          cleanupFailed = true;
          _association!.forceClose();
          try {
            await _association!.closed.timeout(const Duration(seconds: 1));
          } catch (_) {
            /* Retain unconfirmed cleanup. */
          }
        }
      }
    }
    final status = terminal?.status?.code;
    return FindOutcome(
      disposition: failure != null
          ? FindDisposition.failed
          : status == 0
          ? FindDisposition.complete
          : status == 0xFE00
          ? FindDisposition.cancelled
          : failure == null && _cancelled
          ? FindDisposition.stopped
          : FindDisposition.failed,
      status: status,
      failure: failure,
      cancelRequested: _cancelled || (terminal?.cancelRequested ?? false),
      cancellationConfirmed: terminal?.cancellationConfirmed ?? false,
      optionalKeysUnsupported: terminal?.optionalKeysUnsupported ?? false,
      cleanupFailed: cleanupFailed,
      responses: terminal?.responses ?? ordinal,
    );
  }

  FindFailure? _mapFailure(net.DimseException? e) => switch (e) {
    null => null,
    net.DimseIdentifierTooLarge() => FindFailure.identifierTooLarge,
    net.AssociationRejected() => FindFailure.associationRejected,
    net.DimseTimeout() => FindFailure.timeout,
    net.AssociationAborted(:final locallyCancelled, :final source) =>
      locallyCancelled
          ? null
          : source == null
          ? FindFailure.transport
          : FindFailure.peerAbort,
    net.DimseProtocolException() ||
    net.DimseFailureException() => FindFailure.protocol,
  };
}

List<QueryAttribute> projectQueryMetadata(
  dicom.Dataset dataset, [
  List<String> inherited = const [],
]) {
  final charset = dataset.contains(dicom.DicomTags.specificCharacterSet)
      ? dataset.getAll(dicom.DicomTags.specificCharacterSet)
      : inherited;
  final limited =
      dicom.characterSetSupport(charset) ==
      dicom.CharacterSetSupport.unsupported;
  return [
    for (final element in dataset.elements)
      _projectAttribute(element, charset, limited),
  ];
}

QueryAttribute _projectAttribute(
  dicom.DataElement element,
  List<String> charset,
  bool limited,
) {
  final value = element.value;
  return QueryAttribute(
    tag: element.tag.value,
    keyword: dicom.Dictionary.standard.entry(element.tag)?.keyword ?? 'Unknown',
    vr: element.vr.code,
    decodeLimited:
        limited &&
        ['SH', 'LO', 'ST', 'LT', 'UC', 'UT', 'PN'].contains(element.vr.code),
    items: value is dicom.Sequence
        ? value.map((item) => projectQueryMetadata(item, charset))
        : const [],
    values: value is Uint8List
        ? ['${value.length} bytes · value not displayed']
        : value is dicom.Sequence
        ? const []
        : value is List
        ? value.map((v) => v.toString())
        : [value.toString()],
  );
}
