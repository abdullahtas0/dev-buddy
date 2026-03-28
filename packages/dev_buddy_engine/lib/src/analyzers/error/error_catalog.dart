// packages/dev_buddy/lib/src/modules/error_translator/error_catalog.dart
import '../../core/severity.dart';
import 'error_pattern.dart';

/// A collection of error patterns for translating Flutter errors
/// into human-readable diagnostics.
///
/// Create via [ErrorCatalog.en()] for English or [ErrorCatalog.tr()] for Turkish.
/// Extend with custom patterns via the [extraPatterns] constructor parameter.
class ErrorCatalog {
  final List<ErrorPattern> _patterns;

  ErrorCatalog._(this._patterns);

  int get patternCount => _patterns.length;

  /// Tries each pattern in order. Returns the first match or null.
  ErrorMatchResult? translate(String errorMessage) {
    for (final pattern in _patterns) {
      final result = pattern.tryMatch(errorMessage);
      if (result != null) return result;
    }
    return null;
  }

  /// Adds a custom pattern at runtime.
  ///
  /// Prefer using [extraPatterns] in the factory constructor instead.
  /// This method mutates the instance and is kept for backward compatibility.
  @Deprecated('Use ErrorCatalog.en(extraPatterns: [...]) instead')
  void addPattern(ErrorPattern pattern) {
    _patterns.add(pattern);
  }

  /// Returns a new [ErrorCatalog] with the given [pattern] appended.
  ErrorCatalog withPattern(ErrorPattern pattern) {
    return ErrorCatalog._(List.of(_patterns)..add(pattern));
  }

  /// English error catalog with 25 common Flutter errors.
  /// Creates a fresh copy so mutations don't affect the shared list.
  /// Pass [extraPatterns] to extend with custom patterns at creation time.
  factory ErrorCatalog.en({List<ErrorPattern> extraPatterns = const []}) {
    return ErrorCatalog._(List.of(_englishPatterns)..addAll(extraPatterns));
  }

  static final List<ErrorPattern> _englishPatterns = [
    // 1. RenderFlex overflow
    ErrorPattern(
      pattern: RegExp(r'RenderFlex overflowed by ([\d.]+) pixels on the (\w+)'),
      severity: Severity.critical,
      titleBuilder: (m) => 'Layout Overflow (${m[1]}px ${m[2]})',
      descriptionBuilder: (m) =>
          'Content overflows by ${m[1]} pixels on the ${m[2]}. '
          'A Column, Row, or Flex has more content than the available space.',
      suggestions: [
        'Wrap the overflowing child with Expanded or Flexible',
        'Add SingleChildScrollView as a parent widget',
        'Check for fixed-height Containers constraining the content',
        'Use LayoutBuilder to adapt to available space',
      ],
    ),
    // 2. setState after dispose
    ErrorPattern(
      pattern: RegExp(r'setState\(\) called after dispose\(\).*?(\w+State)'),
      severity: Severity.warning,
      titleBuilder: (_) => 'setState After Dispose',
      descriptionBuilder: (m) =>
          'setState() was called on a widget that has already been removed from the tree. '
          'This usually means an async operation (Future, Timer, Stream) completed after navigation.',
      suggestions: [
        'Add a "mounted" check before setState: if (mounted) setState(() {})',
        'Cancel Timers and StreamSubscriptions in dispose()',
        'Use CancelableOperation for Futures that outlive the widget',
      ],
    ),
    // 3. Null check operator
    ErrorPattern(
      pattern: RegExp(r'Null check operator used on a null value'),
      severity: Severity.critical,
      titleBuilder: (_) => 'Null Check Failed',
      descriptionBuilder: (_) =>
          'The "!" operator was used on a null value. Something expected to exist was null.',
      suggestions: [
        'Replace "!" with "??" and provide a fallback value',
        'Use "?." for safe navigation instead of "."',
        'Check if the value was properly initialized before access',
        'Consider using late keyword only when init is guaranteed',
      ],
    ),
    // 4. Type cast error
    ErrorPattern(
      pattern: RegExp(r"type '(\w+)' is not a subtype of type '(\w+)'"),
      severity: Severity.critical,
      titleBuilder: (m) => 'Type Mismatch: ${m[1]} vs ${m[2]}',
      descriptionBuilder: (m) =>
          'Expected type ${m[2]} but got ${m[1]}. This often happens with API responses or generic type parameters.',
      suggestions: [
        'Check your JSON parsing - the API may return a different type than expected',
        'Use "as Type?" with null check instead of "as Type"',
        'Verify generic type parameters match at all call sites',
      ],
    ),
    // 5. RangeError
    ErrorPattern(
      pattern: RegExp(r'RangeError \(index\): Invalid value:.*?(\d+)'),
      severity: Severity.critical,
      titleBuilder: (_) => 'Index Out of Range',
      descriptionBuilder: (m) =>
          'Tried to access index ${m[1]} but the list is shorter. '
          'The list may be empty or the index calculation is wrong.',
      suggestions: [
        'Check list.isEmpty before accessing elements',
        'Verify the index is within bounds: index < list.length',
        'Use list.elementAtOrNull(index) for safe access (Dart 3+)',
      ],
    ),
    // 6. No Material widget found
    ErrorPattern(
      pattern: RegExp(r'No Material widget found'),
      severity: Severity.critical,
      titleBuilder: (_) => 'Missing Material Ancestor',
      descriptionBuilder: (_) =>
          'A Material Design widget (TextField, InkWell, etc.) needs a Material ancestor in the widget tree.',
      suggestions: [
        'Wrap the widget with Material() or Card()',
        'Make sure Scaffold is an ancestor',
        'If using a custom overlay, wrap content with Material(type: MaterialType.transparency)',
      ],
    ),
    // 7. No MediaQuery widget ancestor
    ErrorPattern(
      pattern: RegExp(r'No MediaQuery widget ancestor found'),
      severity: Severity.critical,
      titleBuilder: (_) => 'Missing MediaQuery',
      descriptionBuilder: (_) =>
          'MediaQuery.of(context) was called but no MediaQuery exists above this widget.',
      suggestions: [
        'Ensure MaterialApp or WidgetsApp is at the root of your app',
        'If testing, wrap with MediaQuery(data: MediaQueryData(), child: ...)',
      ],
    ),
    // 8. Scaffold.of() called with context that does not contain Scaffold
    ErrorPattern(
      pattern: RegExp(
        r'Scaffold\.of\(\) called with a context that does not contain a Scaffold',
      ),
      severity: Severity.warning,
      titleBuilder: (_) => 'Wrong Context for Scaffold',
      descriptionBuilder: (_) =>
          'Scaffold.of(context) needs the context of a widget BELOW the Scaffold, not the one that builds it.',
      suggestions: [
        'Use a Builder widget to get a new context below Scaffold',
        'Use ScaffoldMessenger.of(context) for snackbars (preferred)',
        'Use GlobalKey<ScaffoldState> as an alternative',
      ],
    ),
    // 9. Looking up deactivated widget's ancestor
    ErrorPattern(
      pattern: RegExp(r"Looking up a deactivated widget's ancestor"),
      severity: Severity.warning,
      titleBuilder: (_) => 'Deactivated Widget Access',
      descriptionBuilder: (_) =>
          'A widget that has been removed from the tree was accessed. '
          'This usually happens when navigating away while async work is pending.',
      suggestions: [
        'Check "mounted" before using context after await',
        'Cancel subscriptions in dispose()',
        'Use GlobalKey if you need to access widget state across rebuilds',
      ],
    ),
    // 10. Incorrect use of ParentDataWidget
    ErrorPattern(
      pattern: RegExp(r'Incorrect use of ParentDataWidget'),
      severity: Severity.critical,
      titleBuilder: (_) => 'Wrong Parent Widget',
      descriptionBuilder: (_) =>
          'A widget like Expanded, Flexible, or Positioned is used outside its required parent.',
      suggestions: [
        'Expanded/Flexible must be direct children of Row, Column, or Flex',
        'Positioned must be a direct child of Stack',
        'Check that no extra widgets (Padding, Container) wrap between parent and child',
      ],
    ),
    // 11. A build function returned null
    ErrorPattern(
      pattern: RegExp(r'A build function returned null'),
      severity: Severity.critical,
      titleBuilder: (_) => 'Build Returned Null',
      descriptionBuilder: (_) =>
          'The build() method must always return a Widget, never null.',
      suggestions: [
        'Return SizedBox.shrink() instead of null for empty states',
        'Check all conditional branches in build() return a widget',
      ],
    ),
    // 12. Navigator operation requested with a context that does not include a Navigator
    ErrorPattern(
      pattern: RegExp(
        r'Navigator operation requested with a context that does not include a Navigator',
      ),
      severity: Severity.critical,
      titleBuilder: (_) => 'Navigator Not Found',
      descriptionBuilder: (_) =>
          'Navigator.push/pop was called with a context that has no Navigator above it.',
      suggestions: [
        'Ensure MaterialApp is at the root (it provides the Navigator)',
        'Use Builder widget if calling from the same widget that creates MaterialApp',
        'Use a GlobalKey<NavigatorState> for navigation outside the widget tree',
      ],
    ),
    // 13. Duplicate GlobalKey
    ErrorPattern(
      pattern: RegExp(r'Multiple widgets used the same GlobalKey'),
      severity: Severity.critical,
      titleBuilder: (_) => 'Duplicate GlobalKey',
      descriptionBuilder: (_) =>
          'Two widgets share the same GlobalKey. Each GlobalKey must be unique across the entire app.',
      suggestions: [
        'Create a new GlobalKey instance for each widget',
        'Avoid creating GlobalKeys inside build() - use initState() or final fields',
        'Consider using ValueKey or ObjectKey instead if you only need list identification',
      ],
    ),
    // 14. Vertical viewport was given unbounded height
    ErrorPattern(
      pattern: RegExp(r'Vertical viewport was given unbounded height'),
      severity: Severity.critical,
      titleBuilder: (_) => 'Unbounded ListView Height',
      descriptionBuilder: (_) =>
          'A ListView (or other scrollable) is inside a Column/parent without height constraints.',
      suggestions: [
        'Wrap the ListView with Expanded inside a Column',
        'Set shrinkWrap: true on the ListView (caution: hurts performance for large lists)',
        'Give the ListView a fixed height via SizedBox',
      ],
    ),
    // 15. setState() or markNeedsBuild() called during build
    ErrorPattern(
      pattern: RegExp(
        r'setState\(\) or markNeedsBuild\(\) called during build',
      ),
      severity: Severity.warning,
      titleBuilder: (_) => 'setState During Build',
      descriptionBuilder: (_) =>
          'Cannot call setState() while the widget tree is being built. This creates an infinite loop.',
      suggestions: [
        'Move the setState call to a post-frame callback: WidgetsBinding.instance.addPostFrameCallback',
        'Use Future.microtask(() => setState(() {})) to defer the call',
        'Check if you are calling setState inside a StreamBuilder or FutureBuilder callback',
      ],
    ),
    // 16. Bad state: No element
    ErrorPattern(
      pattern: RegExp(r'Bad state: No element'),
      severity: Severity.critical,
      titleBuilder: (_) => 'Empty Collection Access',
      descriptionBuilder: (_) =>
          '.first, .last, or .single was called on an empty list or iterable.',
      suggestions: [
        'Check .isEmpty before accessing .first or .last',
        'Use .firstOrNull (Dart 3+) for safe access',
        'Use .firstWhere with orElse parameter',
      ],
    ),
    // 17. Image not found / Unable to load asset
    ErrorPattern(
      pattern: RegExp(r'Unable to load asset:?\s*(.+)'),
      severity: Severity.warning,
      titleBuilder: (m) => 'Asset Not Found: ${m[1]?.trim()}',
      descriptionBuilder: (m) =>
          'The asset "${m[1]?.trim()}" could not be loaded.',
      suggestions: [
        'Check that the file exists at the exact path specified',
        'Verify the asset is declared in pubspec.yaml under "assets:"',
        'Run "flutter clean" then "flutter pub get" to refresh the asset bundle',
        'Check for typos in the file name or extension (case-sensitive)',
      ],
    ),
    // 18. Failed assertion: line X: 'X': is not true
    ErrorPattern(
      pattern: RegExp(r"Failed assertion:.*?'(.+?)':?\s*is not true"),
      severity: Severity.critical,
      titleBuilder: (m) => 'Assertion Failed: ${m[1]}',
      descriptionBuilder: (m) =>
          'An assertion check "${m[1]}" failed. This is a programming error caught in debug mode.',
      suggestions: [
        'Read the assertion condition carefully - it tells you exactly what went wrong',
        'Check the widget documentation for required parameters or valid ranges',
        'This will crash silently in release mode - fix it now',
      ],
    ),
    // 19. HTTP status codes
    ErrorPattern(
      pattern: RegExp(
        r'(?:HTTP|http|Http)\s*(?:status|error|response)?[:\s]*([45]\d{2})',
      ),
      severity: Severity.warning,
      titleBuilder: (m) => 'HTTP Error ${m[1]}',
      descriptionBuilder: (m) => 'Received HTTP ${m[1]} response.',
      suggestions: [
        'Check your API endpoint URL for typos',
        'Verify authentication token is valid and not expired',
        'Check network connectivity',
      ],
    ),
    // 20. FormatException
    ErrorPattern(
      pattern: RegExp(r'FormatException:?\s*(.+)'),
      severity: Severity.warning,
      titleBuilder: (_) => 'Format Error',
      descriptionBuilder: (m) =>
          'Data format is invalid: ${m[1]}. This often happens when parsing JSON, dates, or numbers.',
      suggestions: [
        'Check the raw data format before parsing',
        'Use tryParse instead of parse for int, double, DateTime',
        'Validate JSON structure before decoding',
      ],
    ),
    // 21. Concurrent modification during iteration
    ErrorPattern(
      pattern: RegExp(r'Concurrent modification during iteration'),
      severity: Severity.critical,
      titleBuilder: (_) => 'List Modified During Iteration',
      descriptionBuilder: (_) =>
          'A list was modified (added to or removed from) while being iterated with a for-each loop.',
      suggestions: [
        'Create a copy of the list before iterating: for (final item in [...list])',
        'Use .removeWhere() or .retainWhere() instead of manual removal',
        'Collect items to remove in a separate list, then remove after the loop',
      ],
    ),
    // 22. LateInitializationError
    ErrorPattern(
      pattern: RegExp(
        r"LateInitializationError: Field '(\w+)' has not been initialized",
      ),
      severity: Severity.critical,
      titleBuilder: (m) => 'Late Field Not Initialized: ${m[1]}',
      descriptionBuilder: (m) =>
          'The "late" field "${m[1]}" was accessed before being assigned a value.',
      suggestions: [
        'Initialize the field in initState() or the constructor',
        'Consider making it nullable instead of late',
        'Use "late final" with a factory if initialization is deferred',
        'Check that the initialization code path always runs before access',
      ],
    ),
    // 23. Unhandled Exception: SocketException
    ErrorPattern(
      pattern: RegExp(r'SocketException:?\s*(.+)'),
      severity: Severity.warning,
      titleBuilder: (_) => 'Network Connection Failed',
      descriptionBuilder: (m) => 'Cannot connect to the server: ${m[1]}',
      suggestions: [
        'Check device internet connectivity',
        'Verify the server URL is correct and reachable',
        'Check if the server is running and accepting connections',
        'On Android, ensure INTERNET permission is in AndroidManifest.xml',
      ],
    ),
    // 24. Ticker was not disposed
    ErrorPattern(
      pattern: RegExp(r'Ticker.*was not disposed'),
      severity: Severity.warning,
      titleBuilder: (_) => 'Animation Ticker Leak',
      descriptionBuilder: (_) =>
          'An AnimationController was not disposed when the widget was removed.',
      suggestions: [
        'Call animationController.dispose() in the dispose() method',
        'Use SingleTickerProviderStateMixin for a single controller',
        'Use TickerProviderStateMixin for multiple controllers',
      ],
    ),
    // 25. BoxConstraints forces an infinite width/height
    ErrorPattern(
      pattern: RegExp(r'BoxConstraints forces an infinite (\w+)'),
      severity: Severity.critical,
      titleBuilder: (m) => 'Infinite ${m[1]} Constraint',
      descriptionBuilder: (m) =>
          'A widget received infinite ${m[1]} constraints. It cannot determine its size.',
      suggestions: [
        'Wrap the widget with SizedBox to give it explicit dimensions',
        'Use Expanded or Flexible inside Row/Column',
        'Check that parent widgets provide bounded constraints',
      ],
    ),
  ];
}
