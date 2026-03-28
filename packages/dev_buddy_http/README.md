# dev_buddy_http

HTTP client wrapper for [DevBuddy](https://pub.dev/packages/dev_buddy) - captures HTTP request/response data from the `http` package and feeds it into DevBuddy's diagnostic overlay.

## Installation

```yaml
dependencies:
  dev_buddy: ^0.1.0
  dev_buddy_http: ^0.1.0
  http: ^1.0.0
```

## Usage

```dart
import 'package:dev_buddy/dev_buddy.dart';
import 'package:dev_buddy_http/dev_buddy_http.dart';
import 'package:http/http.dart' as http;

// Wrap your http client
final client = DevBuddyHttpClient(
  inner: http.Client(),
  onEvent: (event) {
    // Events are fed into DevBuddy's network monitoring
  },
);

// Use normally - all requests are transparently captured
final response = await client.get(Uri.parse('https://api.example.com/data'));
```

## What It Captures

| Field | Description |
|-------|-------------|
| `method` | HTTP method (GET, POST, PUT, DELETE, etc.) |
| `url` | Full request URL |
| `statusCode` | Response status code (null on connection error) |
| `durationMs` | Request-to-response time in milliseconds |
| `responseSize` | Response body size in bytes |
| `errorMessage` | Exception message (on connection error) |

## How It Works

`DevBuddyHttpClient` wraps `http.Client.send()` to intercept all HTTP methods. It:

1. Records the request start time
2. Delegates to the inner client
3. Captures timing, status, and response size
4. Reports the event via the callback
5. Returns the original response (unmodified)

On error, it captures the exception message and re-throws the original exception.

## When to Use This vs NetworkModule

| Approach | Pros | Cons |
|----------|------|------|
| **NetworkModule** (HttpOverrides) | Zero-config, catches ALL HTTP traffic | Doesn't work on Flutter Web |
| **dev_buddy_http** (this package) | Works on all platforms including Web | Only catches requests through the wrapped client |
| **dev_buddy_dio** | Native Dio integration | Only for Dio users |

Use `dev_buddy_http` when you need Web platform support or when `HttpOverrides` is not available.

## Limitations

- Streaming responses are fully buffered to calculate body size
- Request body size is not captured
- Redirect chains are not individually tracked

## Related Packages

- [dev_buddy](https://pub.dev/packages/dev_buddy) - Core diagnostics overlay
- [dev_buddy_dio](https://pub.dev/packages/dev_buddy_dio) - Adapter for Dio
