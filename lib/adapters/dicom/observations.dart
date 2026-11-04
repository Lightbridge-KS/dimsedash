import 'package:dartdicom_net/dartdicom_net.dart' as net;
import 'package:dimsedash_core/dimsedash_core.dart';

EchoObservation projectObservation(net.AssociationObservation e) =>
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
    );
