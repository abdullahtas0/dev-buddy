// packages/dev_buddy/lib/src/ui/panel/module_tab_view.dart
import 'package:flutter/material.dart';
import '../../core/dev_buddy_controller.dart';
import '../../core/dev_buddy_module.dart';
import '../theme/dev_buddy_theme.dart';

/// A widget that renders a [TabBar] + [TabBarView] driven by the registered
/// modules list from a [DevBuddyController].
///
/// Each tab shows the module's icon and name. The tab content is provided
/// by [DevBuddyModule.buildTab] with filtered events for that module.
class ModuleTabView extends StatefulWidget {
  final DevBuddyController controller;

  const ModuleTabView({super.key, required this.controller});

  @override
  State<ModuleTabView> createState() => _ModuleTabViewState();
}

class _ModuleTabViewState extends State<ModuleTabView>
    with TickerProviderStateMixin {
  late TabController _tabController;

  List<DevBuddyModule> get _modules => widget.controller.modules;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _modules.length,
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(ModuleTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.controller.modules.length !=
            widget.controller.modules.length) {
      _tabController.dispose();
      _tabController = TabController(
        length: _modules.length,
        vsync: this,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_modules.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No modules registered.',
            style: DevBuddyTheme.eventDescription,
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tab bar
        TabBar(
          controller: _tabController,
          isScrollable: _modules.length > 3,
          labelColor: const Color(0xFF1E88E5),
          unselectedLabelColor: const Color(0xFF999999),
          indicatorColor: const Color(0xFF1E88E5),
          indicatorWeight: 2,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          dividerColor: Colors.transparent,
          tabs: _modules.map((module) {
            return Tab(
              icon: Icon(module.icon, size: 18),
              text: module.name,
              iconMargin: const EdgeInsets.only(bottom: 4),
            );
          }).toList(),
        ),

        // Tab content
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: widget.controller.events,
            builder: (context, events, _) {
              return TabBarView(
                controller: _tabController,
                children: _modules.map((module) {
                  final filteredEvents =
                      widget.controller.eventsForModule(module.id);
                  return module.buildTab(context, filteredEvents);
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}
