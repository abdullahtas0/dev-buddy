// packages/dev_buddy/test/modules/network/network_analyzer_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dev_buddy/src/modules/network/network_analyzer.dart';
import 'package:dev_buddy/src/modules/network/network_event.dart';
import 'package:dev_buddy/src/core/severity.dart';

void main() {
  group('NetworkAnalyzer', () {
    late NetworkAnalyzer analyzer;

    setUp(() {
      analyzer = const NetworkAnalyzer(slowThresholdMs: 2000);
    });

    test('flags slow requests as warning', () {
      final event = NetworkRequestEvent(
        method: 'GET',
        url: Uri.parse('https://api.example.com/data'),
        statusCode: 200,
        durationMs: 3500,
        requestTimestamp: DateTime.now(),
      );

      final result = analyzer.analyze(event);
      expect(result.severity, equals(Severity.warning));
      expect(
        result.suggestions.any((s) => s.toLowerCase().contains('slow')),
        isTrue,
      );
    });

    test('flags 401 as auth error', () {
      final event = NetworkRequestEvent(
        method: 'GET',
        url: Uri.parse('https://api.example.com/data'),
        statusCode: 401,
        durationMs: 100,
        requestTimestamp: DateTime.now(),
      );

      final result = analyzer.analyze(event);
      expect(result.severity, equals(Severity.critical));
      expect(
        result.suggestions.any((s) => s.toLowerCase().contains('token')),
        isTrue,
      );
    });

    test('flags 500 as server error', () {
      final event = NetworkRequestEvent(
        method: 'POST',
        url: Uri.parse('https://api.example.com/submit'),
        statusCode: 500,
        durationMs: 200,
        requestTimestamp: DateTime.now(),
      );

      final result = analyzer.analyze(event);
      expect(result.severity, equals(Severity.critical));
    });

    test('returns info for successful fast request', () {
      final event = NetworkRequestEvent(
        method: 'GET',
        url: Uri.parse('https://api.example.com/data'),
        statusCode: 200,
        durationMs: 150,
        requestTimestamp: DateTime.now(),
      );

      final result = analyzer.analyze(event);
      expect(result.severity, equals(Severity.info));
    });
  });
}
