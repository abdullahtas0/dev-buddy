// packages/dev_buddy_http/test/http_client_wrapper_test.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:dev_buddy/dev_buddy.dart';
import 'package:dev_buddy_http/dev_buddy_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

void main() {
  group('DevBuddyHttpClient', () {
    late List<NetworkRequestEvent> capturedEvents;

    setUp(() {
      capturedEvents = [];
    });

    test('creates wrapper that implements http.Client', () {
      final inner = http_testing.MockClient(
        (_) async => http.Response('ok', 200),
      );
      final client = DevBuddyHttpClient(
        inner: inner,
        onEvent: capturedEvents.add,
      );
      expect(client, isA<http.BaseClient>());
    });

    test('captures GET request with status code and timing', () async {
      final inner = http_testing.MockClient(
        (_) async => http.Response('{"id": 1}', 200),
      );
      final client = DevBuddyHttpClient(
        inner: inner,
        onEvent: capturedEvents.add,
      );

      await client.get(Uri.parse('https://example.com/api/users'));

      expect(capturedEvents, hasLength(1));
      final event = capturedEvents.first;
      expect(event.method, 'GET');
      expect(event.url.toString(), 'https://example.com/api/users');
      expect(event.statusCode, 200);
      expect(event.durationMs, greaterThanOrEqualTo(0));
      expect(event.errorMessage, isNull);
    });

    test('captures POST request method correctly', () async {
      final inner = http_testing.MockClient(
        (_) async => http.Response('{"id": 1}', 201),
      );
      final client = DevBuddyHttpClient(
        inner: inner,
        onEvent: capturedEvents.add,
      );

      await client.post(
        Uri.parse('https://example.com/api/users'),
        body: jsonEncode({'name': 'test'}),
      );

      expect(capturedEvents, hasLength(1));
      expect(capturedEvents.first.method, 'POST');
      expect(capturedEvents.first.statusCode, 201);
    });

    test('captures error response status codes', () async {
      final inner = http_testing.MockClient(
        (_) async => http.Response('Not Found', 404),
      );
      final client = DevBuddyHttpClient(
        inner: inner,
        onEvent: capturedEvents.add,
      );

      await client.get(Uri.parse('https://example.com/api/missing'));

      expect(capturedEvents, hasLength(1));
      final event = capturedEvents.first;
      expect(event.statusCode, 404);
      expect(event.errorMessage, isNull); // HTTP errors are not exceptions
    });

    test('captures network exception as error event', () async {
      final inner = http_testing.MockClient(
        (_) async => throw http.ClientException('Connection refused'),
      );
      final client = DevBuddyHttpClient(
        inner: inner,
        onEvent: capturedEvents.add,
      );

      expect(
        () => client.get(Uri.parse('https://example.com/api/down')),
        throwsA(isA<http.ClientException>()),
      );

      // Wait for the event to be captured
      await Future<void>.delayed(Duration.zero);

      expect(capturedEvents, hasLength(1));
      final event = capturedEvents.first;
      expect(event.statusCode, isNull);
      expect(event.errorMessage, contains('Connection refused'));
      expect(event.url.toString(), 'https://example.com/api/down');
    });

    test('captures response size from body', () async {
      const body = '{"items": [1,2,3]}';
      final inner = http_testing.MockClient(
        (_) async => http.Response(body, 200),
      );
      final client = DevBuddyHttpClient(
        inner: inner,
        onEvent: capturedEvents.add,
      );

      await client.get(Uri.parse('https://example.com/api/data'));

      expect(capturedEvents.first.responseSize, body.length);
    });

    test('handles multiple sequential requests', () async {
      int callCount = 0;
      final inner = http_testing.MockClient((_) async {
        callCount++;
        return http.Response('response $callCount', 200);
      });
      final client = DevBuddyHttpClient(
        inner: inner,
        onEvent: capturedEvents.add,
      );

      await client.get(Uri.parse('https://example.com/api/first'));
      await client.get(Uri.parse('https://example.com/api/second'));

      expect(capturedEvents, hasLength(2));
      expect(capturedEvents[0].url.path, '/api/first');
      expect(capturedEvents[1].url.path, '/api/second');
    });

    test('delegates send to inner client', () async {
      bool innerCalled = false;
      final inner = http_testing.MockClient((_) async {
        innerCalled = true;
        return http.Response('ok', 200);
      });
      final client = DevBuddyHttpClient(
        inner: inner,
        onEvent: capturedEvents.add,
      );

      await client.get(Uri.parse('https://example.com/test'));

      expect(innerCalled, isTrue);
    });

    test('captures PUT request', () async {
      final inner = http_testing.MockClient(
        (_) async => http.Response('updated', 200),
      );
      final client = DevBuddyHttpClient(
        inner: inner,
        onEvent: capturedEvents.add,
      );

      await client.put(
        Uri.parse('https://example.com/api/users/1'),
        body: jsonEncode({'name': 'updated'}),
      );

      expect(capturedEvents, hasLength(1));
      expect(capturedEvents.first.method, 'PUT');
    });

    test('captures DELETE request', () async {
      final inner = http_testing.MockClient(
        (_) async => http.Response('', 204),
      );
      final client = DevBuddyHttpClient(
        inner: inner,
        onEvent: capturedEvents.add,
      );

      await client.delete(Uri.parse('https://example.com/api/users/1'));

      expect(capturedEvents, hasLength(1));
      expect(capturedEvents.first.method, 'DELETE');
      expect(capturedEvents.first.statusCode, 204);
    });

    test('close delegates to inner client', () async {
      bool closeCalled = false;
      final inner = _CloseTrackingClient(
        onClose: () => closeCalled = true,
      );
      final client = DevBuddyHttpClient(
        inner: inner,
        onEvent: capturedEvents.add,
      );

      client.close();
      expect(closeCalled, isTrue);
    });
  });
}

/// Helper client that tracks close() calls.
class _CloseTrackingClient extends http.BaseClient {
  final void Function() onClose;

  _CloseTrackingClient({required this.onClose});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value(Uint8List.fromList(utf8.encode('ok'))),
      200,
    );
  }

  @override
  void close() {
    onClose();
    super.close();
  }
}
