// packages/dev_buddy_dio/test/dio_interceptor_test.dart
import 'package:dev_buddy/dev_buddy.dart';
import 'package:dev_buddy_dio/dev_buddy_dio.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DevBuddyDioInterceptor', () {
    late List<NetworkRequestEvent> capturedEvents;
    late DevBuddyDioInterceptor interceptor;

    setUp(() {
      capturedEvents = [];
      interceptor = DevBuddyDioInterceptor(
        onEvent: capturedEvents.add,
      );
    });

    test('creates interceptor with required callback', () {
      expect(interceptor, isA<Interceptor>());
    });

    test('captures successful response with timing data', () {
      final requestOptions = RequestOptions(
        path: '/api/users',
        baseUrl: 'https://example.com',
        method: 'GET',
      );

      final response = Response(
        requestOptions: requestOptions,
        statusCode: 200,
        data: '{"id": 1}',
        headers: Headers.fromMap({
          'content-type': ['application/json'],
        }),
      );

      final handler = _MockResponseHandler();
      interceptor.onRequest(requestOptions, _MockRequestHandler());
      interceptor.onResponse(response, handler);

      expect(capturedEvents, hasLength(1));
      final event = capturedEvents.first;
      expect(event.method, 'GET');
      expect(event.url.toString(), 'https://example.com/api/users');
      expect(event.statusCode, 200);
      expect(event.durationMs, greaterThanOrEqualTo(0));
      expect(event.errorMessage, isNull);
    });

    test('captures POST request method correctly', () {
      final requestOptions = RequestOptions(
        path: '/api/users',
        baseUrl: 'https://example.com',
        method: 'POST',
        data: {'name': 'test'},
      );

      final response = Response(
        requestOptions: requestOptions,
        statusCode: 201,
        data: '{"id": 1}',
      );

      interceptor.onRequest(requestOptions, _MockRequestHandler());
      interceptor.onResponse(response, _MockResponseHandler());

      expect(capturedEvents, hasLength(1));
      expect(capturedEvents.first.method, 'POST');
      expect(capturedEvents.first.statusCode, 201);
    });

    test('captures error response with status code', () {
      final requestOptions = RequestOptions(
        path: '/api/missing',
        baseUrl: 'https://example.com',
        method: 'GET',
      );

      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 404,
        ),
        type: DioExceptionType.badResponse,
        message: 'Not Found',
      );

      final handler = _MockErrorHandler();
      interceptor.onRequest(requestOptions, _MockRequestHandler());
      interceptor.onError(dioException, handler);

      expect(capturedEvents, hasLength(1));
      final event = capturedEvents.first;
      expect(event.statusCode, 404);
      expect(event.errorMessage, isNotNull);
      expect(event.url.toString(), 'https://example.com/api/missing');
    });

    test('captures connection timeout error without status code', () {
      final requestOptions = RequestOptions(
        path: '/api/slow',
        baseUrl: 'https://example.com',
        method: 'GET',
      );

      final dioException = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.connectionTimeout,
        message: 'Connection timed out',
      );

      interceptor.onRequest(requestOptions, _MockRequestHandler());
      interceptor.onError(dioException, _MockErrorHandler());

      expect(capturedEvents, hasLength(1));
      final event = capturedEvents.first;
      expect(event.statusCode, isNull);
      expect(event.errorMessage, contains('connectionTimeout'));
    });

    test('calculates response size from string data', () {
      final requestOptions = RequestOptions(
        path: '/api/data',
        baseUrl: 'https://example.com',
        method: 'GET',
      );

      const responseData = '{"items": [1,2,3]}';
      final response = Response(
        requestOptions: requestOptions,
        statusCode: 200,
        data: responseData,
      );

      interceptor.onRequest(requestOptions, _MockRequestHandler());
      interceptor.onResponse(response, _MockResponseHandler());

      expect(capturedEvents.first.responseSize, responseData.length);
    });

    test('handles response without prior onRequest gracefully', () {
      final requestOptions = RequestOptions(
        path: '/api/data',
        baseUrl: 'https://example.com',
        method: 'GET',
      );

      final response = Response(
        requestOptions: requestOptions,
        statusCode: 200,
        data: 'ok',
      );

      // Call onResponse without calling onRequest first
      interceptor.onResponse(response, _MockResponseHandler());

      expect(capturedEvents, hasLength(1));
      // Duration should still be calculated (as 0 if no start time)
      expect(capturedEvents.first.durationMs, greaterThanOrEqualTo(0));
    });

    test('handles multiple concurrent requests independently', () {
      final req1 = RequestOptions(
        path: '/api/first',
        baseUrl: 'https://example.com',
        method: 'GET',
      );
      final req2 = RequestOptions(
        path: '/api/second',
        baseUrl: 'https://example.com',
        method: 'POST',
      );

      interceptor.onRequest(req1, _MockRequestHandler());
      interceptor.onRequest(req2, _MockRequestHandler());

      interceptor.onResponse(
        Response(requestOptions: req2, statusCode: 201),
        _MockResponseHandler(),
      );
      interceptor.onResponse(
        Response(requestOptions: req1, statusCode: 200),
        _MockResponseHandler(),
      );

      expect(capturedEvents, hasLength(2));
      expect(capturedEvents[0].url.path, '/api/second');
      expect(capturedEvents[0].statusCode, 201);
      expect(capturedEvents[1].url.path, '/api/first');
      expect(capturedEvents[1].statusCode, 200);
    });

    test('constructs full URL from baseUrl and path', () {
      final requestOptions = RequestOptions(
        path: '/users/123',
        baseUrl: 'https://api.example.com/v2',
        method: 'GET',
        queryParameters: {'include': 'posts'},
      );

      final response = Response(
        requestOptions: requestOptions,
        statusCode: 200,
      );

      interceptor.onRequest(requestOptions, _MockRequestHandler());
      interceptor.onResponse(response, _MockResponseHandler());

      final url = capturedEvents.first.url;
      expect(url.host, 'api.example.com');
      expect(url.path, contains('users/123'));
    });

    test('passes request through to next handler in onRequest', () {
      final requestOptions = RequestOptions(path: '/test');
      final handler = _MockRequestHandler();

      interceptor.onRequest(requestOptions, handler);

      expect(handler.nextCalled, isTrue);
    });

    test('passes response through to next handler in onResponse', () {
      final requestOptions = RequestOptions(path: '/test');
      final response = Response(
        requestOptions: requestOptions,
        statusCode: 200,
      );
      final handler = _MockResponseHandler();

      interceptor.onResponse(response, handler);

      expect(handler.nextCalled, isTrue);
    });

    test('passes error through to next handler in onError', () {
      final requestOptions = RequestOptions(path: '/test');
      final error = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.unknown,
      );
      final handler = _MockErrorHandler();

      interceptor.onError(error, handler);

      expect(handler.nextCalled, isTrue);
    });

    test('respects maxBodyPreviewLength option', () {
      final longBody = 'x' * 1000;
      interceptor = DevBuddyDioInterceptor(
        onEvent: capturedEvents.add,
        maxBodyPreviewLength: 50,
      );

      final requestOptions = RequestOptions(
        path: '/api/data',
        baseUrl: 'https://example.com',
        method: 'GET',
      );

      final response = Response(
        requestOptions: requestOptions,
        statusCode: 200,
        data: longBody,
      );

      interceptor.onRequest(requestOptions, _MockRequestHandler());
      interceptor.onResponse(response, _MockResponseHandler());

      // responseSize should reflect the full body length
      expect(capturedEvents.first.responseSize, longBody.length);
    });
  });
}

// -- Minimal mock handlers that track if next() was called --

class _MockRequestHandler extends RequestInterceptorHandler {
  bool nextCalled = false;

  @override
  void next(RequestOptions requestOptions) {
    nextCalled = true;
  }
}

class _MockResponseHandler extends ResponseInterceptorHandler {
  bool nextCalled = false;

  @override
  void next(Response response) {
    nextCalled = true;
  }
}

class _MockErrorHandler extends ErrorInterceptorHandler {
  bool nextCalled = false;

  @override
  void next(DioException err) {
    nextCalled = true;
  }
}
