import '../../core/event.dart';
import '../../core/severity.dart';

/// A rule that detects a compound diagnostic from multiple signals.
///
/// Each rule inspects recent events and, if a pattern matches,
/// synthesizes a new [DevBuddyEvent] with a cross-module insight.
class CorrelationRule {
  /// Unique identifier for this rule.
  final String id;

  /// Human-readable name.
  final String name;

  /// Tests whether recent events match this rule's pattern.
  final bool Function(List<DevBuddyEvent> recentEvents) matches;

  /// Creates the compound diagnostic event from matching events.
  final DevBuddyEvent Function(List<DevBuddyEvent> recentEvents) synthesize;

  const CorrelationRule({
    required this.id,
    required this.name,
    required this.matches,
    required this.synthesize,
  });
}

/// Evaluates [CorrelationRule]s against recent events to produce
/// compound diagnostics that connect signals across modules.
///
/// Runs in the Worker Isolate (off main thread) after each batch flush.
/// Rules are stateless — they only inspect the provided event list.
class CorrelationEngine {
  final List<CorrelationRule> _rules;

  /// Tracks which rules have already fired to prevent duplicate alerts.
  /// Reset when events are cleared.
  final Set<String> _firedRules = {};

  CorrelationEngine({List<CorrelationRule>? rules})
      : _rules = rules ?? defaultRules;

  /// Evaluate all rules against recent events.
  /// Returns newly synthesized compound events (may be empty).
  List<DevBuddyEvent> evaluate(List<DevBuddyEvent> recentEvents) {
    final results = <DevBuddyEvent>[];

    for (final rule in _rules) {
      // Skip if this rule already fired (prevent duplicates)
      if (_firedRules.contains(rule.id)) continue;

      if (rule.matches(recentEvents)) {
        results.add(rule.synthesize(recentEvents));
        _firedRules.add(rule.id);
      }
    }

    return results;
  }

  /// Reset fired rules tracking (call when events are cleared).
  void reset() => _firedRules.clear();

  /// Number of registered rules.
  int get ruleCount => _rules.length;

  // ==========================================================================
  // Built-in Correlation Rules
  // ==========================================================================

  static final List<CorrelationRule> defaultRules = [
    _jankPlusHighRebuilds,
    _memoryGrowthPlusNavigation,
    _slowNetworkPlusJank,
    _repeatedAuthFailures,
    _memorySpikePlusLargeResponse,
  ];

  /// Jank + High Rebuilds within recent events → excessive rebuilds causing jank.
  static final _jankPlusHighRebuilds = CorrelationRule(
    id: 'jank_plus_rebuilds',
    name: 'Jank + Excessive Rebuilds',
    matches: (events) {
      final hasJank = events.any((e) => e.module == 'performance' && e.severity.isAtLeast(Severity.warning));
      final hasRebuilds = events.any((e) => e.module == 'rebuilds' && e.severity.isAtLeast(Severity.warning));
      return hasJank && hasRebuilds;
    },
    synthesize: (events) {
      final rebuildEvent = events.firstWhere(
        (e) => e.module == 'rebuilds' && e.severity.isAtLeast(Severity.warning),
      );
      final topRebuilders = rebuildEvent.metadata?['top_rebuilders'];
      final widgetNames = topRebuilders is List
          ? topRebuilders.take(3).map((r) => r is Map ? r['widget'] : r).join(', ')
          : 'unknown widgets';

      return DevBuddyEvent(
        module: 'correlation',
        severity: Severity.critical,
        title: 'Excessive Rebuilds Causing UI Jank',
        description: 'Widgets [$widgetNames] are rebuilding excessively, '
            'which is directly causing frame drops and visible jank.',
        suggestions: [
          'Add const constructors to frequently rebuilding widgets',
          'Use context.select() instead of context.watch() for granular updates',
          'Extract expensive subtrees into separate widgets with const keys',
          'Check if setState() is being called unnecessarily',
        ],
        metadata: {'rule': 'jank_plus_rebuilds'},
      );
    },
  );

  /// Memory growth + Screen navigation → possible dispose leak.
  static final _memoryGrowthPlusNavigation = CorrelationRule(
    id: 'memory_growth_navigation',
    name: 'Memory Growth + Navigation',
    matches: (events) {
      final hasMemoryWarning = events.any(
        (e) => e.module == 'memory' && e.severity.isAtLeast(Severity.warning),
      );
      // Check if there are multiple screen-related events
      final navEvents = events.where(
        (e) => e.metadata?['screen'] != null || e.module == 'navigation',
      );
      return hasMemoryWarning && navEvents.length >= 2;
    },
    synthesize: (events) {
      final memEvent = events.firstWhere(
        (e) => e.module == 'memory' && e.severity.isAtLeast(Severity.warning),
      );

      return DevBuddyEvent(
        module: 'correlation',
        severity: Severity.warning,
        title: 'Memory Grows During Navigation',
        description: 'Memory usage increases as you navigate between screens. '
            'This suggests screen widgets or controllers are not being disposed properly.',
        suggestions: [
          'Check that all controllers are disposed in dispose() method',
          'Cancel StreamSubscriptions and Timers in dispose()',
          'Verify NavigatorObserver is tracking screen lifecycle',
          'Use DevTools Memory view to identify retained objects',
        ],
        metadata: {
          'rule': 'memory_growth_navigation',
          'memory_info': memEvent.metadata,
        },
      );
    },
  );

  /// Slow network response followed by jank → main thread JSON parsing.
  static final _slowNetworkPlusJank = CorrelationRule(
    id: 'slow_network_jank',
    name: 'Slow Network + Jank',
    matches: (events) {
      final hasSlowNetwork = events.any(
        (e) => e.module == 'network' && e.severity.isAtLeast(Severity.warning),
      );
      final hasJank = events.any(
        (e) => e.module == 'performance' && e.severity.isAtLeast(Severity.warning),
      );
      if (!hasSlowNetwork || !hasJank) return false;

      // Check temporal proximity (slow network before jank)
      final networkTime = events
          .where((e) => e.module == 'network' && e.severity.isAtLeast(Severity.warning))
          .map((e) => e.timestamp)
          .firstOrNull;
      final jankTime = events
          .where((e) => e.module == 'performance' && e.severity.isAtLeast(Severity.warning))
          .map((e) => e.timestamp)
          .firstOrNull;

      if (networkTime == null || jankTime == null) return false;
      // Jank must occur AFTER network response, within 2 seconds
      final diffMs = jankTime.difference(networkTime).inMilliseconds;
      return diffMs >= 0 && diffMs < 2000;
    },
    synthesize: (events) {
      final networkEvent = events.firstWhere(
        (e) => e.module == 'network' && e.severity.isAtLeast(Severity.warning),
      );
      final url = networkEvent.metadata?['url'] ?? 'unknown';

      return DevBuddyEvent(
        module: 'correlation',
        severity: Severity.warning,
        title: 'Network Response Causing Jank',
        description: 'A slow network response from $url was followed by UI jank. '
            'The response may be parsed on the main thread, blocking rendering.',
        suggestions: [
          'Use compute() or Isolate.run() to parse large JSON responses off the main thread',
          'Consider streaming/chunked response parsing for large payloads',
          'Add a loading indicator while processing the response',
        ],
        metadata: {
          'rule': 'slow_network_jank',
          'url': url,
        },
      );
    },
  );

  /// Repeated 401 errors → broken token refresh.
  static final _repeatedAuthFailures = CorrelationRule(
    id: 'repeated_auth_failures',
    name: 'Repeated Auth Failures',
    matches: (events) {
      final authFailures = events.where(
        (e) => e.module == 'network' && e.metadata?['status_code'] == 401,
      ).length;
      return authFailures >= 3;
    },
    synthesize: (events) {
      final count = events
          .where((e) => e.module == 'network' && e.metadata?['status_code'] == 401)
          .length;

      return DevBuddyEvent(
        module: 'correlation',
        severity: Severity.critical,
        title: 'Token Refresh Mechanism Broken',
        description: '$count consecutive 401 Unauthorized responses detected. '
            'The authentication token refresh is likely failing silently.',
        suggestions: [
          'Check if the refresh token has expired',
          'Verify the token refresh endpoint is responding correctly',
          'Add retry logic with exponential backoff for auth failures',
          'Log the full refresh token response for debugging',
        ],
        metadata: {'rule': 'repeated_auth_failures', 'count': count},
      );
    },
  );

  /// Memory spike after large network response → large resource loaded.
  static final _memorySpikePlusLargeResponse = CorrelationRule(
    id: 'memory_spike_large_response',
    name: 'Memory Spike + Large Response',
    matches: (events) {
      final hasMemoryWarning = events.any(
        (e) => e.module == 'memory' && e.severity.isAtLeast(Severity.warning),
      );
      final hasLargeResponse = events.any((e) {
        if (e.module != 'network') return false;
        final size = e.metadata?['response_size'];
        return size is int && size > 500 * 1024; // > 500KB
      });
      return hasMemoryWarning && hasLargeResponse;
    },
    synthesize: (events) {
      final largeResponse = events.firstWhere((e) {
        final size = e.metadata?['response_size'];
        return e.module == 'network' && size is int && size > 500 * 1024;
      });
      final url = largeResponse.metadata?['url'] ?? 'unknown';
      final sizeMb = ((largeResponse.metadata?['response_size'] ?? 0) / 1024 / 1024).toStringAsFixed(1);

      return DevBuddyEvent(
        module: 'correlation',
        severity: Severity.warning,
        title: 'Large Resource Causing Memory Spike',
        description: 'A ${sizeMb}MB response from $url is causing a memory spike. '
            'Large resources should be streamed or cached efficiently.',
        suggestions: [
          'For images: use cacheWidth/cacheHeight to limit decoded size',
          'For JSON: use streaming JSON parser for large payloads',
          'Consider server-side pagination to reduce response size',
          'Cache responses locally to avoid repeated large downloads',
        ],
        metadata: {
          'rule': 'memory_spike_large_response',
          'url': url,
          'size_mb': sizeMb,
        },
      );
    },
  );
}
