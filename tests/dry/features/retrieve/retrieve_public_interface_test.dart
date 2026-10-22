import 'package:dimsedash/features/retrieve/retrieve.dart' as retrieve;
import 'package:dimsedash/features/retrieve/retrieve_preview.dart' as legacy;
import 'package:dimsedash/features/retrieve/retrieve_view.dart' as legacy_view;
import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Retrieve barrel forwards existing declarations and widget construction',
    () {
      expect(retrieve.RetrieveScope, legacy.RetrieveScope);
      expect(retrieve.RetrieveMethod, legacy.RetrieveMethod);
      expect(retrieve.RetrieveScenario, legacy.RetrieveScenario);
      expect(retrieve.RetrieveSeed, legacy.RetrieveSeed);
      expect(retrieve.RetrieveDraft, legacy.RetrieveDraft);
      expect(retrieve.RetrieveSnapshot, legacy.RetrieveSnapshot);
      expect(retrieve.SampleReceipt, legacy.SampleReceipt);
      expect(retrieve.RetrieveSample, legacy.RetrieveSample);
      expect(
        retrieve.RetrievePreviewController,
        legacy.RetrievePreviewController,
      );
      expect(retrieve.RetrievePreviewView, legacy_view.RetrievePreviewView);
      expect(
        retrieve.retrieveSettingsDiffer,
        same(legacy.retrieveSettingsDiffer),
      );
      const node = PacsNode(
        id: 'n',
        label: 'Synthetic',
        host: '192.0.2.1',
        port: 104,
        calledAe: 'PACS_AET',
      );
      const config = AppConfiguration(node: node);
      final controller = legacy.RetrievePreviewController('n');
      addTearDown(controller.dispose);
      final source = retrieve.RetrieveSeed(
        sourceId: 'source',
        node: node,
        client: config.client,
        scope: retrieve.RetrieveScope.study,
        description: 'Synthetic',
        uids: {'StudyInstanceUID': '2.25.1'},
      );
      expect(controller.open(source), isTrue);
      controller.chooseFolder(true);
      expect(controller.showSample(config, echoActive: false), isNull);
      String? opened;
      var reviewed = false;
      final view = retrieve.RetrievePreviewView(
        controller: controller,
        header: const SizedBox(),
        sampleId: controller.latest!.id,
        onSample: (id) => opened = id,
        onReview: () => reviewed = true,
      );
      view.onSample(view.sampleId!);
      view.onReview();
      expect(view, isA<legacy_view.RetrievePreviewView>());
      expect(opened, controller.latest!.id);
      expect(reviewed, isTrue);
    },
  );
}
