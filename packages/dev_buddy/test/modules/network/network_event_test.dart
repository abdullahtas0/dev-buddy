// packages/dev_buddy/test/modules/network/network_event_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dev_buddy/src/modules/network/network_event.dart';

void main() {
  group('NetworkRequestEvent', () {
    test('creates from request/response data', () {
      final event = NetworkRequestEvent(
        method: 'GET',
        url: Uri.parse('https://api.example.com/users'),
        statusCode: 200,
        durationMs: 150,
        requestTimestamp: DateTime(2026, 3, 26),
        responseSize: 1024,
      );

      expect(event.method, equals('GET'));
      expect(event.statusCode, equals(200));
      expect(event.durationMs, equals(150));
      expect(event.isSuccess, isTrue);
      expect(event.isError, isFalse);
    });

    test('identifies error status codes', () {
      final event = NetworkRequestEvent(
        method: 'POST',
        url: Uri.parse('https://api.example.com/login'),
        statusCode: 401,
        durationMs: 50,
        requestTimestamp: DateTime(2026, 3, 26),
      );

      expect(event.isSuccess, isFalse);
      expect(event.isError, isTrue);
    });

    test('toJson serializes correctly', () {
      final event = NetworkRequestEvent(
        method: 'GET',
        url: Uri.parse('https://api.example.com/users'),
        statusCode: 200,
        durationMs: 150,
        requestTimestamp: DateTime(2026, 3, 26),
      );

      final json = event.toJson();
      expect(json['method'], equals('GET'));
      expect(json['status_code'], equals(200));
    });
  });
}
