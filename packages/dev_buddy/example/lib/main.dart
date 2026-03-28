// packages/dev_buddy/example/lib/main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dev_buddy/dev_buddy.dart';

import 'pages/jank_demo_page.dart';
import 'pages/error_demo_page.dart';
import 'pages/network_demo_page.dart';
import 'pages/memory_demo_page.dart';
import 'pages/rebuild_demo_page.dart';

void main() {
  runApp(const DevBuddyExampleApp());
}

class DevBuddyExampleApp extends StatelessWidget {
  const DevBuddyExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevBuddy Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.light,
      ),
      builder: (context, child) => DevBuddyOverlayImpl(
        enabled: kDebugMode,
        modules: [
          PerformanceModule(),
          ErrorTranslatorModule(),
          NetworkModule(),
          MemoryModule(),
          RebuildTrackerModule(),
        ],
        child: child!,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DevBuddy Demos'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Tap a demo to trigger intentional issues.\n'
            'Open the DevBuddy overlay pill to see diagnostics.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _DemoCard(
            icon: Icons.speed,
            title: 'Jank Demo',
            subtitle: 'ListView with 1000 heavy items using BoxShadow and '
                'Opacity widgets. Triggers the Performance module.',
            color: Colors.orange,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JankDemoPage()),
            ),
          ),
          _DemoCard(
            icon: Icons.bug_report,
            title: 'Error Demo',
            subtitle: 'Overflow errors and setState-after-dispose. '
                'Triggers the Error Translator module.',
            color: Colors.red,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ErrorDemoPage()),
            ),
          ),
          _DemoCard(
            icon: Icons.wifi,
            title: 'Network Demo',
            subtitle: 'Simulates slow API calls, 401, 404, and 500 errors. '
                'Triggers the Network module.',
            color: Colors.blue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NetworkDemoPage()),
            ),
          ),
          _DemoCard(
            icon: Icons.memory,
            title: 'Memory Demo',
            subtitle: 'Creates TextEditingControllers in a loop without '
                'disposing them. Triggers the Memory module.',
            color: Colors.purple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MemoryDemoPage()),
            ),
          ),
          _DemoCard(
            icon: Icons.refresh,
            title: 'Rebuild Demo',
            subtitle: 'Widget that calls setState every 100ms causing '
                'excessive rebuilds. Triggers the Rebuild Tracker module.',
            color: Colors.teal,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RebuildDemoPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DemoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
