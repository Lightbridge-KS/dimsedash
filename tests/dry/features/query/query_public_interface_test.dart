import 'package:dimsedash/features/query/query.dart' as query;
import 'package:dimsedash/features/query/query_preview.dart' as legacy;
import 'package:dimsedash/features/query/query_view.dart' as legacy_view;
import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Query barrel forwards the original declarations and handoff contract',
    () {
      expect(query.QueryLevel, legacy.QueryLevel);
      expect(query.PreviewScenario, legacy.PreviewScenario);
      expect(query.IdentifierPurpose, legacy.IdentifierPurpose);
      expect(query.QueryEditor, legacy.QueryEditor);
      expect(query.PreviewKey, legacy.PreviewKey);
      expect(query.PreviewEntry, legacy.PreviewEntry);
      expect(query.QueryPreviewDraft, legacy.QueryPreviewDraft);
      expect(query.PreviewMatch, legacy.PreviewMatch);
      expect(query.PreviewRequest, legacy.PreviewRequest);
      expect(query.PreviewResultContext, legacy.PreviewResultContext);
      expect(query.QueryPreviewController, legacy.QueryPreviewController);
      expect(query.QueryPreviewView, legacy_view.QueryPreviewView);
      expect(query.keyName, same(legacy.keyName));
      expect(query.keyTag, same(legacy.keyTag));
      expect(query.keyVr, same(legacy.keyVr));
      final controller = legacy.QueryPreviewController('one');
      addTearDown(controller.dispose);
      const config = AppConfiguration(
        node: PacsNode(
          id: 'one',
          label: 'Synthetic node',
          host: '192.0.2.1',
          port: 104,
          calledAe: 'PACS_AET',
        ),
      );
      controller.run(config, echoActive: false);
      final legacy_view.QueryRetrieveSelection selection = (
        row: controller.result!.rows.first,
        result: controller.result!,
      );
      final query.QueryRetrieveSelection forwarded = selection;
      final view = query.QueryPreviewView(
        controller: controller,
        header: const SizedBox(),
        onRetrieve: (value) => expect(value, forwarded),
      );
      view.onRetrieve(selection);
      expect(forwarded.result, same(controller.result));
      expect(view, isA<legacy_view.QueryPreviewView>());
    },
  );
}
