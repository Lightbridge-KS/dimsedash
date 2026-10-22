import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bindings/configuration.dart';
import '../preview/retrieve_preview_model.dart';

Future<void> showRetrieveReceiptDialog(
  BuildContext context,
  SampleReceipt receipt, {
  required bool thumbnail,
}) => showDialog<void>(
  context: context,
  builder: (context) => _ReceiptDialog(receipt: receipt, thumbnail: thumbnail),
);

class _ReceiptDialog extends ConsumerStatefulWidget {
  const _ReceiptDialog({required this.receipt, required this.thumbnail});
  final SampleReceipt receipt;
  final bool thumbnail;
  @override
  ConsumerState<_ReceiptDialog> createState() => _ReceiptDialogState();
}

class _ReceiptDialogState extends ConsumerState<_ReceiptDialog> {
  bool shown = false;
  @override
  Widget build(BuildContext context) {
    final reveal = ref.watch(revealProvider);
    final r = widget.receipt;
    return AlertDialog(
      title: Text(
        widget.thumbnail
            ? 'Thumbnail · placeholder'
            : 'Saved-object headers · synthetic',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Synthetic receipt only. No file exists or has been read.',
            ),
            if (!r.saved)
              const Text(
                'Save failed · no saved headers or thumbnail available.',
              )
            else if (!widget.thumbnail)
              Text(
                reveal
                    ? 'PatientName = SAMPLE^ONLY\nPatientID = SYNTHETIC\nDelivery = ${r.id}\nHeaders are fixed illustration values, not decoded DICOM.'
                    : 'Headers hidden · use session Reveal values',
              ),
            if (r.saved && widget.thumbnail) ...[
              if (r.unsupported)
                const Text(
                  'Unsupported preview · illustrative codec limitation',
                )
              else if (shown && reveal)
                const SizedBox(
                  height: 120,
                  width: 180,
                  child: Center(child: Icon(Icons.image_outlined, size: 64)),
                )
              else
                const Text('Thumbnail placeholder hidden'),
              if (!r.unsupported)
                TextButton(
                  onPressed: reveal
                      ? () => setState(() => shown = !shown)
                      : null,
                  child: Text(
                    shown ? 'Hide placeholder' : 'Reveal placeholder',
                  ),
                ),
              const Text(
                'No image pixels, decoding or diagnostic interpretation. Session Reveal and separate object reveal are required.',
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
