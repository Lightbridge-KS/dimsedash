import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bindings/configuration.dart';
import '../bindings/echo.dart';
import '../features/settings/settings_view.dart';
import '../features/nodes/node_library.dart';
import '../features/echo/echo_view.dart';
import '../features/query/query.dart';
import '../ui/workbench_header.dart';
import '../features/retrieve/retrieve.dart';

enum _Destination {
  nodes('Nodes', Icons.dns_outlined),
  files('Received files', Icons.folder_outlined),
  history('History', Icons.history),
  settings('Settings', Icons.settings_outlined);

  const _Destination(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum _NodePage { library, workspace, run, retrieveReview }

typedef _Location = ({
  _Destination page,
  _NodePage inner,
  String? nodeId,
  String? runId,
});
const _library = (
  page: _Destination.nodes,
  inner: _NodePage.library,
  nodeId: null,
  runId: null,
);

class WorkbenchShell extends ConsumerStatefulWidget {
  const WorkbenchShell({super.key});
  @override
  ConsumerState<WorkbenchShell> createState() => _WorkbenchShellState();
}

class _WorkbenchShellState extends ConsumerState<WorkbenchShell> {
  _Location _location = _library;
  _Location _runOrigin = _library;
  QuerySession? _query;
  String? _displayedQueryRunId;
  ({String runId, int ordinal})? _retrieve;
  OperationKind _runKind = OperationKind.echo;
  bool _restoreRetrieveFocus = false;
  final _retrieveFocus = FocusNode(debugLabel: 'Review retrieve');
  WorkbenchOperation _operation = WorkbenchOperation.echo;
  bool _selecting = false;
  int _navigation = 0, _restoreLibraryFocus = 0;
  final _viewRunFocus = FocusNode(debugLabel: 'View run');

  @override
  void dispose() {
    _query?.dispose();
    _retrieveFocus.dispose();
    _viewRunFocus.dispose();
    super.dispose();
  }

  void _navigate(_Location location, {bool restoreLibrary = false}) {
    setState(() {
      _navigation++;
      _location = location;
      if (restoreLibrary) _restoreLibraryFocus++;
    });
  }

  void _allNodes() => _navigate(_library, restoreLibrary: true);

  void _queryContextChanged() {
    // Parent/child navigation can change evidence ownership without a runtime
    // event. Rebuild the shell strip only when that displayed run changes.
    if (mounted && _displayedQueryRunId != _query?.runId) {
      setState(() => _displayedQueryRunId = _query?.runId);
    }
  }

  void _destination(_Destination page) {
    if (page == _Destination.nodes) {
      _navigate(_library);
      return;
    }
    _navigate((
      page: page,
      inner: _NodePage.library,
      nodeId: null,
      runId: null,
    ));
  }

  void _viewRun(String runId) {
    // An obsolete run view may link to the newer retained run; preserve its origin.
    if (_location.inner != _NodePage.run) _runOrigin = _location;
    _runKind =
        ref.read(echoStateProvider).summary?.operation ?? OperationKind.echo;
    _navigate((
      page: _Destination.nodes,
      inner: _NodePage.run,
      nodeId: null,
      runId: runId,
    ));
  }

  void _backFromRun() {
    final config = ref.read(configurationProvider);
    var origin = _runOrigin;
    if (origin.nodeId != null && config.node?.id != origin.nodeId) {
      origin = _library;
    }
    if (origin.inner == _NodePage.retrieveReview &&
        _query?.nodeId != origin.nodeId) {
      origin = _library;
    }
    _navigate(origin, restoreLibrary: origin != _runOrigin);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _viewRunFocus.context != null) {
        _viewRunFocus.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(configurationProvider);
    ref.listen(configurationProvider, (_, next) {
      if (_query != null && next.selectedNodeId != _query!.nodeId) {
        _query!.dispose();
        _query = null;
        _retrieve = null;
        _operation = WorkbenchOperation.echo;
      }
      _query?.syncConfiguration(next);
      if (_location.nodeId != null && next.node?.id != _location.nodeId) {
        _allNodes();
      }
    });
    final reveal = ref.watch(revealProvider);
    final echo = ref.watch(echoStateProvider);
    final atLibrary =
        _location.page == _Destination.nodes &&
        _location.inner == _NodePage.library;
    final displaysEvidence =
        _location.page == _Destination.nodes &&
        ((_location.inner == _NodePage.workspace &&
                ((_operation == WorkbenchOperation.echo &&
                        echo.summary?.operation == OperationKind.echo) ||
                    (_operation == WorkbenchOperation.query &&
                        echo.summary?.operation == OperationKind.find &&
                        _query?.runId == echo.summary?.id)) &&
                echo.request?.node.id == _location.nodeId) ||
            (_location.inner == _NodePage.run &&
                echo.summary?.id == _location.runId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('DimseDash'),
        actions: [
          TextButton.icon(
            onPressed: () => ref.read(revealProvider.notifier).toggle(),
            icon: Icon(reveal ? Icons.visibility : Icons.visibility_off),
            label: Text(reveal ? 'Mask values' : 'Reveal values'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          _WorkbenchSidebar(
            configuration: config,
            selectedPage: _location.page,
            onPageSelected: _destination,
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                if (echo.summary != null && !displaysEvidence)
                  Material(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${echo.active ? '${echo.summary!.operation == OperationKind.echo ? 'Echo' : 'Query'} running' : 'Latest ${echo.summary!.operation == OperationKind.echo ? 'Echo' : 'Query'}'} · ${echo.request?.node.label ?? 'Frozen target'}',
                            ),
                          ),
                          TextButton(
                            focusNode: _viewRunFocus,
                            onPressed: () => _viewRun(echo.summary!.id),
                            child: const Text('View run'),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Preserve only library presentation; abandoned Settings drafts are discarded.
                      Offstage(
                        offstage: !atLibrary,
                        child: TickerMode(
                          enabled: atLibrary,
                          child: ExcludeFocus(
                            excluding: !atLibrary,
                            child: NodeLibrary(
                              onOpen: _openNode,
                              restoreFocus: _restoreLibraryFocus,
                            ),
                          ),
                        ),
                      ),
                      if (!atLibrary)
                        Positioned.fill(
                          child: switch (_location.page) {
                            _Destination.nodes => switch (_location.inner) {
                              _NodePage.workspace => _workspace(config),
                              _NodePage.run =>
                                _runKind == OperationKind.find
                                    ? FindRunView(
                                        key: ValueKey(_location.runId),
                                        runId: _location.runId!,
                                        onBack: _backFromRun,
                                      )
                                    : EchoRunView(
                                        key: ValueKey(_location.runId),
                                        runId: _location.runId!,
                                        onBack: _backFromRun,
                                      ),
                              _NodePage.retrieveReview => _retrieveReview(
                                config,
                              ),
                              _NodePage.library => const SizedBox.shrink(),
                            },
                            _Destination.settings => const SettingsView(),
                            _Destination.files => _placeholder(
                              Icons.folder_outlined,
                              'No received files',
                            ),
                            _Destination.history => _placeholder(
                              Icons.history,
                              'No run history',
                            ),
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _workspace(AppConfiguration config) {
    final header = WorkbenchHeader(
      config: config,
      nodeId: _location.nodeId!,
      onBack: _allNodes,
      operation: _operation,
      onOperationChanged: (value) => setState(() => _operation = value),
    );
    return switch (_operation) {
      WorkbenchOperation.echo => EchoView(
        key: ValueKey(_location.nodeId),
        nodeId: _location.nodeId!,
        onBack: _allNodes,
        workspaceHeader: header,
      ),
      WorkbenchOperation.query => FindView(
        key: ValueKey(_location.nodeId),
        session: _query!,
        header: header,
        onRetrieve: _reviewRetrieve,
        retrieveFocus: _retrieveFocus,
        restoreRetrieveFocus: _restoreRetrieveFocus,
      ),
    };
  }

  Widget _retrieveReview(AppConfiguration config) {
    final target = _retrieve;
    final result = target == null
        ? null
        : ref.read(operationRunnerProvider)?.findResult(target.runId);
    final row = result?.rows
        .where((r) => r.ordinal == target!.ordinal)
        .firstOrNull;
    final header = WorkbenchHeader(
      config: config,
      nodeId: _location.nodeId!,
      onBack: _backToResults,
      backLabel: 'Back to results',
    );
    if (result == null || row == null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          header,
          const Text(
            'This query target is no longer retained. Return to results and query again.',
          ),
        ],
      );
    }
    return RetrieveTargetReview(result: result, row: row, header: header);
  }

  void _reviewRetrieve(QuerySelection selection) {
    if (selection.result.request.targetChanged(
          ref.read(configurationProvider),
        ) ||
        selection.row.targetProblem(selection.result.request.identifier) !=
            null) {
      return;
    }
    _retrieve = (runId: selection.result.runId, ordinal: selection.row.ordinal);
    _restoreRetrieveFocus = false;
    _navigate((
      page: _Destination.nodes,
      inner: _NodePage.retrieveReview,
      nodeId: selection.result.request.node.id,
      runId: null,
    ));
  }

  void _backToResults() {
    final nodeId = _query?.nodeId;
    if (nodeId == null || ref.read(configurationProvider).node?.id != nodeId) {
      _allNodes();
      return;
    }
    _restoreRetrieveFocus = true;
    _operation = WorkbenchOperation.query;
    _navigate((
      page: _Destination.nodes,
      inner: _NodePage.workspace,
      nodeId: nodeId,
      runId: null,
    ));
  }

  Widget _placeholder(IconData icon, String title) => _WorkflowPlaceholder(
    icon: icon,
    title: title,
    description: 'This workflow will be available in a later preview.',
    onOpenSettings: () => _destination(_Destination.settings),
  );

  Future<bool> _openNode(PacsNode node) async {
    if (_selecting) return false;
    final navigation = _navigation;
    _selecting = true;
    try {
      final config = ref.read(configurationProvider);
      if (config.selectedNodeId != node.id) {
        final error = await ref
            .read(configurationProvider.notifier)
            .changeNode(SelectNode(config.revision, node.id));
        if (!mounted || navigation != _navigation) return false;
        if (error != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error.message)));
          return false;
        }
      }
      if (!mounted ||
          navigation != _navigation ||
          ref.read(configurationProvider).node?.id != node.id) {
        return false;
      }
      if (_query?.nodeId != node.id) {
        _query?.dispose();
        _query = QuerySession(node.id, ref.read(operationRunnerProvider));
        _displayedQueryRunId = null;
        _query!.addListener(_queryContextChanged);
        _retrieve = null;
        _restoreRetrieveFocus = false;
        _operation = WorkbenchOperation.echo;
      }
      _navigate((
        page: _Destination.nodes,
        inner: _NodePage.workspace,
        nodeId: node.id,
        runId: null,
      ));
      return true;
    } finally {
      _selecting = false;
    }
  }
}

class _WorkbenchSidebar extends StatelessWidget {
  const _WorkbenchSidebar({
    required this.configuration,
    required this.selectedPage,
    required this.onPageSelected,
  });
  final AppConfiguration configuration;
  final _Destination selectedPage;
  final ValueChanged<_Destination> onPageSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 220,
    child: Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      for (final page in _Destination.values)
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          leading: Icon(page.icon),
                          title: Text(page.label),
                          selected: selectedPage == page,
                          onTap: () => onPageSelected(page),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        const Text('LOCAL RECEIVER'),
                        Text(configuration.client.callingAe),
                        Text('Port ${configuration.client.listenPort}'),
                        const SizedBox(height: 12),
                        Semantics(
                          label: 'Local receiver stopped. Receiver unavailable in this build.',
                          excludeSemantics: true,
                          child: Row(
                            key: ValueKey('receiver-status'),
                            children: [
                              Icon(Icons.stop_circle_outlined, size: 18),
                              SizedBox(width: 8),
                              Flexible(child: Text('Stopped')),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Receiver unavailable in this build.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _WorkflowPlaceholder extends StatelessWidget {
  const _WorkflowPlaceholder({
    required this.icon,
    required this.title,
    required this.description,
    required this.onOpenSettings,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(description),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onOpenSettings,
              child: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
