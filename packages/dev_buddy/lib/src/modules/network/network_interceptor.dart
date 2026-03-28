// packages/dev_buddy/lib/src/modules/network/network_interceptor.dart
// ignore_for_file: close_sinks
import 'dart:convert';
import 'dart:io';
import 'package:dev_buddy_engine/dev_buddy_engine.dart';

/// Custom [HttpOverrides] that intercepts all HTTP traffic for DevBuddy.
///
/// Wraps the existing [HttpClient] to capture request/response metadata
/// without modifying the actual HTTP behavior. Chains with any previous
/// [HttpOverrides] to avoid breaking other interceptors.
class DevBuddyHttpOverrides extends HttpOverrides {
  final void Function(NetworkRequestEvent event) onEvent;
  final HttpOverrides? previous;

  DevBuddyHttpOverrides({required this.onEvent, this.previous});

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client =
        previous?.createHttpClient(context) ?? super.createHttpClient(context);
    return _InstrumentedHttpClient(client, onEvent);
  }
}

class _InstrumentedHttpClient implements HttpClient {
  final HttpClient _inner;
  final void Function(NetworkRequestEvent event) _onEvent;

  _InstrumentedHttpClient(this._inner, this._onEvent);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    final startTime = DateTime.now();
    try {
      final request = await _inner.openUrl(method, url);
      return _InstrumentedRequest(request, method, url, startTime, _onEvent);
    } catch (e) {
      _onEvent(
        NetworkRequestEvent(
          method: method,
          url: url,
          durationMs: DateTime.now().difference(startTime).inMilliseconds,
          requestTimestamp: startTime,
          errorMessage: e.toString(),
        ),
      );
      rethrow;
    }
  }

  // Delegate all other HttpClient methods to _inner
  @override
  Future<HttpClientRequest> open(
    String method,
    String host,
    int port,
    String path,
  ) => openUrl(method, Uri(scheme: 'http', host: host, port: port, path: path));
  @override
  Future<HttpClientRequest> get(String host, int port, String path) =>
      open('GET', host, port, path);
  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('GET', url);
  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      open('POST', host, port, path);
  @override
  Future<HttpClientRequest> postUrl(Uri url) => openUrl('POST', url);
  @override
  Future<HttpClientRequest> put(String host, int port, String path) =>
      open('PUT', host, port, path);
  @override
  Future<HttpClientRequest> putUrl(Uri url) => openUrl('PUT', url);
  @override
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      open('DELETE', host, port, path);
  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => openUrl('DELETE', url);
  @override
  Future<HttpClientRequest> head(String host, int port, String path) =>
      open('HEAD', host, port, path);
  @override
  Future<HttpClientRequest> headUrl(Uri url) => openUrl('HEAD', url);
  @override
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      open('PATCH', host, port, path);
  @override
  Future<HttpClientRequest> patchUrl(Uri url) => openUrl('PATCH', url);

  @override
  set autoUncompress(bool value) => _inner.autoUncompress = value;
  @override
  bool get autoUncompress => _inner.autoUncompress;
  @override
  set connectionTimeout(Duration? value) => _inner.connectionTimeout = value;
  @override
  Duration? get connectionTimeout => _inner.connectionTimeout;
  @override
  set idleTimeout(Duration value) => _inner.idleTimeout = value;
  @override
  Duration get idleTimeout => _inner.idleTimeout;
  @override
  set maxConnectionsPerHost(int? value) => _inner.maxConnectionsPerHost = value;
  @override
  int? get maxConnectionsPerHost => _inner.maxConnectionsPerHost;
  @override
  set userAgent(String? value) => _inner.userAgent = value;
  @override
  String? get userAgent => _inner.userAgent;
  @override
  set authenticate(
    Future<bool> Function(Uri url, String scheme, String? realm)? f,
  ) => _inner.authenticate = f;
  @override
  set authenticateProxy(
    Future<bool> Function(String host, int port, String scheme, String? realm)?
    f,
  ) => _inner.authenticateProxy = f;
  @override
  set badCertificateCallback(
    bool Function(X509Certificate cert, String host, int port)? callback,
  ) => _inner.badCertificateCallback = callback;
  @override
  set connectionFactory(
    Future<ConnectionTask<Socket>> Function(
      Uri url,
      String? proxyHost,
      int? proxyPort,
    )?
    f,
  ) => _inner.connectionFactory = f;
  @override
  set findProxy(String Function(Uri url)? f) => _inner.findProxy = f;
  @override
  set keyLog(Function(String line)? callback) => _inner.keyLog = callback;
  @override
  void addCredentials(
    Uri url,
    String realm,
    HttpClientCredentials credentials,
  ) => _inner.addCredentials(url, realm, credentials);
  @override
  void addProxyCredentials(
    String host,
    int port,
    String realm,
    HttpClientCredentials credentials,
  ) => _inner.addProxyCredentials(host, port, realm, credentials);
  @override
  void close({bool force = false}) => _inner.close(force: force);
}

class _InstrumentedRequest implements HttpClientRequest {
  final HttpClientRequest _inner;
  final String _method;
  final Uri _url;
  final DateTime _startTime;
  final void Function(NetworkRequestEvent event) _onEvent;

  _InstrumentedRequest(
    this._inner,
    this._method,
    this._url,
    this._startTime,
    this._onEvent,
  );

  @override
  Future<HttpClientResponse> close() async {
    try {
      final response = await _inner.close();
      final durationMs = DateTime.now().difference(_startTime).inMilliseconds;
      _onEvent(
        NetworkRequestEvent(
          method: _method,
          url: _url,
          statusCode: response.statusCode,
          durationMs: durationMs,
          requestTimestamp: _startTime,
          responseSize: response.contentLength > 0
              ? response.contentLength
              : null,
        ),
      );
      return response;
    } catch (e) {
      _onEvent(
        NetworkRequestEvent(
          method: _method,
          url: _url,
          durationMs: DateTime.now().difference(_startTime).inMilliseconds,
          requestTimestamp: _startTime,
          errorMessage: e.toString(),
        ),
      );
      rethrow;
    }
  }

  // Delegate all HttpClientRequest methods to _inner
  @override
  bool get bufferOutput => _inner.bufferOutput;
  @override
  set bufferOutput(bool value) => _inner.bufferOutput = value;
  @override
  int get contentLength => _inner.contentLength;
  @override
  set contentLength(int value) => _inner.contentLength = value;
  @override
  Encoding get encoding => _inner.encoding;
  @override
  set encoding(Encoding value) => _inner.encoding = value;
  @override
  bool get followRedirects => _inner.followRedirects;
  @override
  set followRedirects(bool value) => _inner.followRedirects = value;
  @override
  int get maxRedirects => _inner.maxRedirects;
  @override
  set maxRedirects(int value) => _inner.maxRedirects = value;
  @override
  bool get persistentConnection => _inner.persistentConnection;
  @override
  set persistentConnection(bool value) => _inner.persistentConnection = value;
  @override
  void abort([Object? exception, StackTrace? stackTrace]) =>
      _inner.abort(exception, stackTrace);
  @override
  void add(List<int> data) => _inner.add(data);
  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _inner.addError(error, stackTrace);
  @override
  Future addStream(Stream<List<int>> stream) => _inner.addStream(stream);
  @override
  HttpConnectionInfo? get connectionInfo => _inner.connectionInfo;
  @override
  List<Cookie> get cookies => _inner.cookies;
  @override
  Future<HttpClientResponse> get done => _inner.done;
  @override
  Future flush() => _inner.flush();
  @override
  HttpHeaders get headers => _inner.headers;
  @override
  String get method => _inner.method;
  @override
  Uri get uri => _inner.uri;
  @override
  void write(Object? object) => _inner.write(object);
  @override
  void writeAll(Iterable objects, [String separator = '']) =>
      _inner.writeAll(objects, separator);
  @override
  void writeCharCode(int charCode) => _inner.writeCharCode(charCode);
  @override
  void writeln([Object? object = '']) => _inner.writeln(object);
}
