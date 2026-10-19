import 'dart:async';
import 'dart:io';

import 'package:dartdicom_net/dartdicom_net.dart' as net;
import 'package:dimsedash_core/dimsedash_core.dart';

class DartDicomGateway implements DimseGateway {
  @override
  GatewayRun echo(
    String runId,
    ResolvedEchoRequest request,
    void Function(EchoObservation) observe,
  ) => _EchoRun(runId, request, observe);
}

final class _EchoRun implements GatewayRun, net.AssociationObserver {
  _EchoRun(this.id, this.request, this.observe) {
    done = _execute();
  }
  final String id;
  final ResolvedEchoRequest request;
  final void Function(EchoObservation) observe;
  final _cancellation = net.AssociationCancellation();
  net.Association? _association;
  int? _observedStatus;
  @override
  late final Future<EchoOutcome> done;
  @override
  void stop() => _cancellation.cancel();
  @override
  void forceClose() {
    _cancellation.cancel();
    _association?.forceClose();
  }

  @override
  void record(net.AssociationObservation e) {
    if (e.direction == net.ObservationDirection.incoming &&
        e.commandField == 0x8030 &&
        e.responseTo == 1) {
      _observedStatus = e.status;
    }
    observe(
      EchoObservation(
        sequence: e.sequence,
        peerImplementationClassUid: e.peerImplementationClassUid,
        maxInvoked: e.maxInvoked,
        maxPerformed: e.maxPerformed,
        timeoutPhase: switch (e.timeoutKind) {
          net.TimeoutKind.connect => EchoTimeoutPhase.connect,
          net.TimeoutKind.acse => EchoTimeoutPhase.association,
          net.TimeoutKind.dimse => EchoTimeoutPhase.dimse,
          net.TimeoutKind.network => EchoTimeoutPhase.idle,
          null => null,
        },
        elapsedMicros: e.elapsed.inMicroseconds,
        kind: EvidenceKind.values.byName(e.kind.name),
        direction: EvidenceDirection.values.byName(e.direction.name),
        contexts: e.contexts.map(
          (c) => NegotiatedContext(
            id: c.id,
            scuRole: c.scuRole,
            scpRole: c.scpRole,
            abstractSyntax: c.abstractSyntax,
            proposed: c.proposedTransferSyntaxes,
            result: c.result,
            selected: c.selectedTransferSyntax,
          ),
        ),
        result: e.result,
        source: e.source,
        reason: e.reason,
        command: e.commandField,
        messageId: e.messageId,
        responseTo: e.responseTo,
        status: e.status,
        contextId: e.contextId,
        peerMaxPduLength: e.peerMaxPduLength,
      ),
    );
  }

  Future<EchoOutcome> _execute() async {
    int? status;
    EchoFailure? failure;
    bool cleanupFailed = false;
    try {
      final t = request.client.timeouts;
      final ae = net.ApplicationEntity(
        aeTitle: request.client.callingAe,
        requestedContexts: net.PresentationContexts.verification,
        observer: this,
        timeouts: net.Timeouts(
          connect: Duration(seconds: t.connect),
          acse: Duration(seconds: t.association),
          dimse: Duration(seconds: t.dimse),
          network: Duration(seconds: t.idle),
        ),
      );
      final association = await ae.associate(
        request.node.host,
        request.node.port,
        aeTitle: request.node.calledAe,
        cancellation: _cancellation,
        associationId: id,
      );
      _association = association;
      if (association.acceptedContexts.isEmpty) {
        failure = EchoFailure.contextRejected;
      } else {
        status = (await association.sendCEcho()).code;
      }
      try {
        await association.release();
      } catch (_) {
        cleanupFailed = true;
        await association.abort();
      }
    } on net.AssociationRejected {
      failure = EchoFailure.associationRejected;
    } on net.DimseTimeout {
      failure = EchoFailure.timeout;
    } on net.AssociationAborted catch (e) {
      if (!e.locallyCancelled) {
        failure = e.source == null
            ? EchoFailure.transport
            : EchoFailure.peerAbort;
      }
    } on SocketException {
      failure = EchoFailure.connection;
    } on net.DimseException {
      failure = EchoFailure.protocol;
    } catch (_) {
      failure = EchoFailure.unexpected;
    } finally {
      // Await cleanup before resolving done and freeing app admission.
      if (_association != null) {
        try {
          await _association!.abort().timeout(const Duration(seconds: 2));
          await _association!.closed.timeout(const Duration(seconds: 2));
        } catch (_) {
          cleanupFailed = true;
          _association!.forceClose();
          try {
            await _association!.closed.timeout(const Duration(seconds: 2));
          } catch (_) {
            // closed retains an unconfirmed-cleanup failure after forceClose.
            // Preserve it separately from the observed DIMSE result.
          }
        }
      }
    }
    status ??= _observedStatus;
    final disposition = status == 0
        ? (cleanupFailed || _cancellation.isCancelled
              ? EchoDisposition.warning
              : EchoDisposition.success)
        : _cancellation.isCancelled && status == null && failure == null
        ? EchoDisposition.stopped
        : EchoDisposition.failed;
    return EchoOutcome(
      disposition,
      status: status,
      failure: failure,
      cleanupFailed: cleanupFailed,
    );
  }
}
