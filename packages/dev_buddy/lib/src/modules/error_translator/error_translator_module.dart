// packages/dev_buddy/lib/src/modules/error_translator/error_translator_module.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/dev_buddy_config.dart';
import '../../core/dev_buddy_event.dart';
import '../../core/dev_buddy_module.dart';
import '../../core/severity.dart';
import 'error_catalog.dart';
import 'error_pattern.dart';

/// Intercepts Flutter errors and translates them into human-readable diagnostics.
///
/// Uses [FlutterError.onError] and [PlatformDispatcher.instance.onError]
/// to catch all errors, then matches against the [ErrorCatalog].
class ErrorTranslatorModule extends DevBuddyModule {
  @override
  String get id => 'errors';
  @override
  String get name => 'Errors';
  @override
  IconData get icon => Icons.bug_report;

  late ErrorCatalog _catalog;
  late void Function(DevBuddyEvent) _onEvent;
  FlutterExceptionHandler? _previousFlutterErrorHandler;
  ErrorCallback? _previousPlatformErrorHandler;
  bool _disposed = false;

  /// Optional: allow users to add custom patterns.
  final List<ErrorPattern> customPatterns;

  ErrorTranslatorModule({this.customPatterns = const []});

  @override
  void initialize({
    required DevBuddyConfig config,
    required void Function(DevBuddyEvent) onEvent,
  }) {
    _disposed = false;
    _onEvent = onEvent;

    // Initialize catalog based on locale.
    // Turkish catalog is implemented in the i18n phase.
    // Until then, English is the fallback for all locales.
    _catalog = ErrorCatalog.en(extraPatterns: customPatterns);

    // Chain onto existing error handlers (don't replace)
    _previousFlutterErrorHandler = FlutterError.onError;
    FlutterError.onError = _handleFlutterError;

    _previousPlatformErrorHandler = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = _handlePlatformError;
  }

  @override
  void dispose() {
    _disposed = true;
    FlutterError.onError = _previousFlutterErrorHandler;
    PlatformDispatcher.instance.onError = _previousPlatformErrorHandler;
  }

  void _handleFlutterError(FlutterErrorDetails details) {
    if (_disposed) return;
    _translateAndEmit(details.exceptionAsString());

    // Forward to previous handler (e.g., default red screen).
    // Wrap in try-catch to prevent a throwing previous handler from
    // crashing the entire error handling chain.
    try {
      _previousFlutterErrorHandler?.call(details);
    } catch (e) {
      debugPrint('DevBuddy: previous FlutterError handler threw: $e');
    }
  }

  bool _handlePlatformError(Object error, StackTrace stack) {
    if (_disposed) return _previousPlatformErrorHandler?.call(error, stack) ?? false;
    _translateAndEmit(error.toString());

    // Forward to previous handler, guarded against throws.
    try {
      return _previousPlatformErrorHandler?.call(error, stack) ?? false;
    } catch (e) {
      debugPrint('DevBuddy: previous platform error handler threw: $e');
      return false;
    }
  }

  void _translateAndEmit(String errorMessage) {
    final match = _catalog.translate(errorMessage);

    if (match != null) {
      _onEvent(DevBuddyEvent(
        module: id,
        severity: match.severity,
        title: match.title,
        description: match.description,
        suggestions: match.suggestions,
        metadata: {'raw_error': errorMessage},
      ));
    } else {
      // Unknown error - still report it, just less detailed
      _onEvent(DevBuddyEvent(
        module: id,
        severity: Severity.warning,
        title: 'Unrecognized Error',
        description: errorMessage.length > 200
            ? '${errorMessage.substring(0, 200)}...'
            : errorMessage,
        suggestions: [
          'Search this error message on Google or StackOverflow',
          'Check the stack trace in the console for the source location',
        ],
        metadata: {'raw_error': errorMessage, 'matched': false},
      ));
    }
  }

  @override
  Widget buildTab(BuildContext context, List<DevBuddyEvent> events) {
    if (events.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
              SizedBox(height: 12),
              Text(
                'No errors caught',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.all(12),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _ErrorEventTile(event: event);
      },
    );
  }
}

class _ErrorEventTile extends StatelessWidget {
  final DevBuddyEvent event;
  const _ErrorEventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(event.severity.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(event.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(event.description,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (event.suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('How to fix:',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E88E5))),
              const SizedBox(height: 4),
              ...event.suggestions.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('  \u2022 ', style: TextStyle(fontSize: 11)),
                        Expanded(
                          child: Text(s,
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF1E88E5))),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
