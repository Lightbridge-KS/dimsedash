import 'package:flutter/material.dart';

/// Controlled tabs: selection belongs to the shell or feature session.
class WorkbenchTabs extends StatefulWidget {
  const WorkbenchTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.secondary = false,
  });
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final bool secondary;
  @override
  State<WorkbenchTabs> createState() => _WorkbenchTabsState();
}

class _WorkbenchTabsState extends State<WorkbenchTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(
    length: widget.labels.length,
    initialIndex: widget.index,
    vsync: this,
  );
  @override
  void didUpdateWidget(WorkbenchTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.index != widget.index) _controller.index = widget.index;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = widget.labels.map((label) => Tab(text: label)).toList();
    return widget.secondary
        ? TabBar.secondary(
            controller: _controller,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: tabs,
            onTap: widget.onChanged,
          )
        : TabBar(
            controller: _controller,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: tabs,
            onTap: widget.onChanged,
          );
  }
}
