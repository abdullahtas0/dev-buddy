# DevBuddy

**Human-Readable Flutter Diagnostics -- Not Metrics, Solutions**

*Metrikleri Degil, Cozumleri Gosteren Flutter Gelistirici Asistani*

[![pub package](https://img.shields.io/pub/v/dev_buddy.svg)](https://pub.dev/packages/dev_buddy)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Tests](https://img.shields.io/badge/tests-155%20passing-brightgreen)

DevBuddy is an in-app diagnostics overlay for Flutter that translates raw performance metrics into plain-language suggestions. Instead of telling you "frame time: 32ms," it tells you *why* your UI is janking and *how* to fix it -- right inside your running app.

---

## Why DevBuddy?

| Feature | Flutter DevTools | DevBuddy |
|---------|-----------------|----------|
| Where | Separate browser window | In-app overlay |
| Language | Technical metrics & graphs | Human-readable suggestions |
| Actions | "Frame time: 32ms" | "UI jank detected. Use `ListView.builder` instead of `ListView`" |
| Setup | Connect debugger, navigate tabs | 3 lines of code |
| Release impact | N/A | Zero bytes (tree-shaken) |

DevBuddy does not replace DevTools. It complements it by surfacing the most common issues in a format that requires zero context-switching.

---

## Screenshots

<!-- TODO: Replace with actual screen recordings before launch -->
![DevBuddy Overview](https://placeholder.com/devbuddy-overview.gif)
![Error Translation](https://placeholder.com/devbuddy-errors.gif)

---

## Quick Start

Add the dependency:

```yaml
dependencies:
  dev_buddy: ^0.1.0
```

Wrap your app:

```dart
import 'package:dev_buddy/dev_buddy.dart';
import 'package:flutter/foundation.dart';

MaterialApp(
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
)
```

That's it. A floating pill appears in the corner of your app. Tap it to open the diagnostic panel.

In release builds, the overlay compiles to a transparent pass-through with zero runtime cost via tree-shaking.

---

## Modules

### PerformanceModule

Monitors frame rendering via `SchedulerBinding.addTimingsCallback` and detects UI jank in real time.

**What it detects:**
- Single-frame jank (frame time exceeding 16.7ms threshold)
- Consecutive jank streaks indicating sustained performance issues
- FPS drops below acceptable thresholds

**Example output:**

> UI Jank Detected (34ms frame)
> Frame took 2x longer than the 16.7ms budget.
>
> Suggestions:
> - Use `ListView.builder` instead of `ListView` for long lists
> - Move heavy computation off the main isolate with `compute()`
> - Check for unnecessary widget rebuilds in the Rebuilds tab

### ErrorTranslatorModule

Intercepts Flutter errors via `FlutterError.onError` and `PlatformDispatcher.instance.onError`, then matches them against a catalog of 25+ known error patterns with human-readable explanations.

**What it detects:**
- RenderFlex overflow errors
- setState called after dispose
- Null check operator failures
- Missing Material/Scaffold ancestors
- Duplicate GlobalKey usage
- And 20+ more common Flutter errors

**Example output:**

> Layout Overflow (42.0px bottom)
> A widget is trying to render more content than its parent allows.
>
> How to fix:
> - Wrap the overflowing widget with `Expanded` or `Flexible`
> - Use `SingleChildScrollView` if the content should scroll
> - Check for hardcoded `height`/`width` values

**Custom error patterns:**

```dart
ErrorTranslatorModule(
  customPatterns: [
    ErrorPattern(
      pattern: RegExp(r'MyCustomException: (.+)'),
      severity: Severity.warning,
      titleBuilder: (m) => 'Custom Error: ${m[1]}',
      descriptionBuilder: (m) => 'Something specific to your app went wrong.',
      suggestions: ['Check your custom logic', 'Review input validation'],
    ),
  ],
)
```

### NetworkModule

Monitors all HTTP traffic via `HttpOverrides`, capturing requests from any HTTP client (Dio, http, `HttpClient`, etc.) without additional configuration.

**What it detects:**
- Slow requests exceeding the configurable threshold (default: 2000ms)
- HTTP error responses (4xx, 5xx)
- Network failures and timeouts
- Request/response timing and size

**Example output:**

> Slow API Response (3420ms)
> GET /api/users took 3420ms, exceeding the 2000ms threshold.
>
> Suggestions:
> - Check server-side performance for this endpoint
> - Consider adding pagination to reduce payload size
> - Implement caching for frequently requested data

### MemoryModule

Samples `ProcessInfo.currentRss` every 5 seconds and applies a leak heuristic to detect monotonic memory growth.

**What it detects:**
- High RSS memory usage exceeding the configurable threshold (default: 150 MB)
- Monotonic memory growth patterns suggesting potential leaks
- Memory growth rate calculations

**Example output:**

> Memory Usage High (287 MB)
> RSS memory has been growing steadily over the last 60 samples.
>
> Suggestions:
> - Check for undisposed controllers or streams
> - Look for images or large objects held in state
> - Use DevTools Memory tab for precise Dart heap analysis

### RebuildTrackerModule

Hooks into Flutter's `debugOnRebuildDirtyWidget` callback to count widget rebuilds per frame, using `Type`-based keys for performance.

**What it detects:**
- Excessive widget rebuilds per frame (configurable threshold, default: 30)
- Top rebuilding widgets ranked by count
- Rebuild patterns that indicate missing `const` constructors or improper state management

**Example output:**

> Excessive Rebuilds (47 widgets/frame)
> 47 widgets rebuilt in a single frame, exceeding the threshold of 30.
>
> Suggestions:
> - Add `const` constructors where possible
> - Extract frequently-changing subtrees into separate widgets
> - Use `ValueListenableBuilder` or `Selector` to limit rebuild scope

Only active in debug mode. The callback is stripped entirely in release builds.

---

## Optional Adapters

The core `NetworkModule` intercepts traffic via `HttpOverrides`, which works with any HTTP client out of the box. For richer metadata or when `HttpOverrides` is not available (e.g., web), use one of the adapter packages:

### dev_buddy_dio

```yaml
dependencies:
  dev_buddy_dio: ^0.1.0
```

```dart
import 'package:dev_buddy_dio/dev_buddy_dio.dart';

final dio = Dio();
dio.interceptors.add(DevBuddyDioInterceptor(
  onEvent: (event) => networkModule.reportEvent(event),
));
```

### dev_buddy_http

```yaml
dependencies:
  dev_buddy_http: ^0.1.0
```

```dart
import 'package:dev_buddy_http/dev_buddy_http.dart';

final client = DevBuddyHttpClient(
  inner: http.Client(),
  onEvent: (event) => networkModule.reportEvent(event),
);
final response = await client.get(Uri.parse('https://api.example.com'));
```

---

## Configuration

Customize thresholds and behavior via `DevBuddyConfig`:

```dart
DevBuddyOverlayImpl(
  config: DevBuddyConfig(
    maxEvents: 100,
    minSeverity: Severity.info,
    jankThresholdMs: 16.7,
    slowNetworkThresholdMs: 2000,
    memoryWarningThresholdMb: 150,
    rebuildWarningThreshold: 30,
    enablePerScreenMetrics: true,
    locale: 'en',
  ),
  // ...
)
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `maxEvents` | `int` | `100` | Maximum events kept in memory (FIFO eviction) |
| `minSeverity` | `Severity` | `info` | Minimum severity to display. Events below are silently dropped |
| `jankThresholdMs` | `double` | `16.7` | Frame duration threshold for jank detection. Set to `8.4` for 120Hz devices |
| `slowNetworkThresholdMs` | `int` | `2000` | Request duration (ms) to flag as slow |
| `memoryWarningThresholdMb` | `int` | `150` | RSS memory threshold (MB) to trigger warnings |
| `rebuildWarningThreshold` | `int` | `30` | Widget rebuild count per frame to trigger warnings |
| `enablePerScreenMetrics` | `bool` | `true` | Track metrics per screen via `NavigatorObserver` |
| `locale` | `String?` | `null` | Locale override (`'en'`, `'tr'`). Auto-detects if null |

---

## Per-Screen Metrics

Track diagnostics per screen by adding the navigator observer:

```dart
final observer = DevBuddyNavigatorObserverImpl();

MaterialApp(
  navigatorObservers: [observer],
  builder: (context, child) => DevBuddyOverlayImpl(
    enabled: kDebugMode,
    config: DevBuddyConfig(enablePerScreenMetrics: true),
    modules: [PerformanceModule(), ErrorTranslatorModule()],
    child: child!,
  ),
)
```

---

## Internationalization (i18n)

DevBuddy supports multiple languages for its UI text without depending on the `intl` package.

**Supported languages:**
- English (`en`) -- default
- Turkish (`tr`)

**Setting the locale:**

```dart
DevBuddyOverlayImpl(
  config: DevBuddyConfig(locale: 'tr'),
  // ...
)
```

When `locale` is `null` (the default), DevBuddy auto-detects from the device locale.

---

## Exporting Reports

Export diagnostic events as JSON or human-readable text for bug reports, Slack messages, or log files:

```dart
import 'package:dev_buddy/dev_buddy.dart';

final exporter = DevBuddyExporterImpl(
  report: DevBuddyReport(
    generatedAt: DateTime.now(),
    deviceInfo: {'platform': 'iOS', 'version': '17.0'},
    events: controller.events,
  ),
);

// JSON format (for programmatic consumption)
final json = exporter.exportJson();

// Text format (for sharing in bug reports)
final text = exporter.exportText();
```

**Example text output:**

```
=== DevBuddy Report ===
Generated: 2026-03-26T14:30:00.000Z

--- Device Info ---
platform: iOS
version: 17.0

--- Events (2) ---

#1 [CRITICAL] performance - UI Jank Detected (34ms frame)
   Frame took 2x longer than the 16.7ms budget.
   Suggestions:
   - Use ListView.builder instead of ListView for long lists
   - Move heavy computation off the main isolate with compute()

#2 [WARNING] network - Slow API Response (3420ms)
   GET /api/users took 3420ms, exceeding the 2000ms threshold.
   Suggestions:
   - Check server-side performance for this endpoint
```

---

## Architecture

DevBuddy follows a modular plugin architecture:

- **`DevBuddyModule`** -- abstract base class. Each module observes one aspect of the app and emits `DevBuddyEvent`s.
- **`DevBuddyController`** -- aggregates events from all modules with 500ms batching to prevent UI thrashing.
- **`DevBuddyOverlayImpl`** -- the overlay widget. Renders a draggable pill with severity-based coloring and an expandable bottom sheet panel.
- **Zero external dependencies** -- the core package depends only on the Flutter SDK.

Writing a custom module:

```dart
class MyCustomModule extends DevBuddyModule {
  @override
  String get id => 'custom';
  @override
  String get name => 'Custom';
  @override
  IconData get icon => Icons.extension;

  @override
  void initialize({
    required DevBuddyConfig config,
    required void Function(DevBuddyEvent event) onEvent,
  }) {
    // Set up your monitoring logic here
  }

  @override
  void dispose() {
    // Clean up
  }

  @override
  Widget buildTab(BuildContext context, List<DevBuddyEvent> events) {
    return const Center(child: Text('My custom diagnostics'));
  }
}
```

---

## Contributing

Contributions are welcome. Please see [CONTRIBUTING.md](../../CONTRIBUTING.md) for guidelines.

---

## License

MIT License. See [LICENSE](../../LICENSE) for details.
