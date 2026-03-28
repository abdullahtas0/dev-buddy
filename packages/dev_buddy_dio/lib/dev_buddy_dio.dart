// packages/dev_buddy_dio/lib/dev_buddy_dio.dart
/// Dio adapter for DevBuddy diagnostics.
///
/// Provides [DevBuddyDioInterceptor] to capture HTTP traffic
/// from Dio and feed it into DevBuddy's network monitoring.
library dev_buddy_dio;

export 'src/dio_interceptor.dart';
