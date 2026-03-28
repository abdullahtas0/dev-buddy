# dev_buddy_dio

Dio interceptor adapter for [DevBuddy](https://pub.dev/packages/dev_buddy) - captures HTTP request/response data and feeds it into DevBuddy's diagnostic overlay.

## Installation

```yaml
dependencies:
  dev_buddy: ^0.2.0
  dev_buddy_dio: ^0.2.0
  dio: ^5.0.0
```

## Usage

```dart
import 'package:dev_buddy/dev_buddy.dart';
import 'package:dev_buddy_dio/dev_buddy_dio.dart';
import 'package:dio/dio.dart';

// Create your Dio instance
final dio = Dio();

// Create the NetworkModule
final networkModule = NetworkModule();

// Add the interceptor
dio.interceptors.add(DevBuddyDioInterceptor(
  onEvent: (event) {
    // Events are fed into DevBuddy's network monitoring
    // via the NetworkModule's event callback
  },
));
```

## What It Captures

| Field | Description |
|-------|-------------|
| `method` | HTTP method (GET, POST, PUT, DELETE, etc.) |
| `url` | Full request URL |
| `statusCode` | Response status code (null on connection error) |
| `durationMs` | Request-to-response time in milliseconds |
| `responseSize` | Estimated response body size in characters |
| `errorMessage` | Dio exception type and message (on error) |

## Configuration

```dart
DevBuddyDioInterceptor(
  onEvent: (event) { /* ... */ },
  maxBodyPreviewLength: 2048,  // Max chars for size estimation (default: 2048)
);
```

## How It Works

1. **onRequest**: Records the request start time
2. **onResponse**: Calculates duration, captures status code and response size
3. **onError**: Captures the Dio exception type and error message

The interceptor is non-blocking and always delegates to the next handler in the chain. It never modifies requests or responses.

## Limitations

- Response size is estimated from `data.toString().length`, not actual byte count
- Binary response bodies may produce inaccurate size estimates
- Request body size is not captured (only response size)
- Redirect chains are not individually tracked

## Related Packages

- [dev_buddy](https://pub.dev/packages/dev_buddy) - Core diagnostics overlay
- [dev_buddy_http](https://pub.dev/packages/dev_buddy_http) - Adapter for the `http` package
