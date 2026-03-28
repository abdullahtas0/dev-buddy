import 'severity.dart';

/// Configuration for the DevBuddy diagnostic engine.
///
/// All values have sensible defaults. Immutable with [copyWith] for updates.
class DevBuddyConfig {
  /// Maximum number of events to keep in memory (FIFO eviction).
  final int maxEvents;

  /// Minimum severity to process. Events below this threshold are silently dropped.
  final Severity minSeverity;

  /// If true, metrics are tracked per-screen via NavigatorObserver.
  final bool enablePerScreenMetrics;

  /// Locale override. If null, auto-detects from device.
  /// Supported: 'en', 'tr'
  final String? locale;

  /// Jank threshold in milliseconds. Frames slower than this trigger warnings.
  /// Default: 16.7ms (60 FPS). Set to 8.4 for 120Hz devices.
  final double jankThresholdMs;

  /// Network request duration threshold (ms) to flag as slow.
  final int slowNetworkThresholdMs;

  /// Memory usage threshold (MB) to trigger warnings.
  final int memoryWarningThresholdMb;

  /// Widget rebuild count threshold per frame to trigger warnings.
  final int rebuildWarningThreshold;

  /// Maximum RAM budget for state store in bytes (default: 20MB).
  final int stateStoreBudgetBytes;

  const DevBuddyConfig({
    this.maxEvents = 100,
    this.minSeverity = Severity.info,
    this.enablePerScreenMetrics = true,
    this.locale,
    this.jankThresholdMs = 16.7,
    this.slowNetworkThresholdMs = 2000,
    this.memoryWarningThresholdMb = 150,
    this.rebuildWarningThreshold = 30,
    this.stateStoreBudgetBytes = 20 * 1024 * 1024, // 20MB
  });

  DevBuddyConfig copyWith({
    int? maxEvents,
    Severity? minSeverity,
    bool? enablePerScreenMetrics,
    String? locale,
    double? jankThresholdMs,
    int? slowNetworkThresholdMs,
    int? memoryWarningThresholdMb,
    int? rebuildWarningThreshold,
    int? stateStoreBudgetBytes,
  }) {
    return DevBuddyConfig(
      maxEvents: maxEvents ?? this.maxEvents,
      minSeverity: minSeverity ?? this.minSeverity,
      enablePerScreenMetrics:
          enablePerScreenMetrics ?? this.enablePerScreenMetrics,
      locale: locale ?? this.locale,
      jankThresholdMs: jankThresholdMs ?? this.jankThresholdMs,
      slowNetworkThresholdMs:
          slowNetworkThresholdMs ?? this.slowNetworkThresholdMs,
      memoryWarningThresholdMb:
          memoryWarningThresholdMb ?? this.memoryWarningThresholdMb,
      rebuildWarningThreshold:
          rebuildWarningThreshold ?? this.rebuildWarningThreshold,
      stateStoreBudgetBytes:
          stateStoreBudgetBytes ?? this.stateStoreBudgetBytes,
    );
  }
}
