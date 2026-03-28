// packages/dev_buddy_http/lib/dev_buddy_http.dart
/// http package adapter for DevBuddy diagnostics.
///
/// Provides [DevBuddyHttpClient] to capture HTTP traffic
/// from the `http` package and feed it into DevBuddy's network monitoring.
library dev_buddy_http;

export 'src/http_client_wrapper.dart';
