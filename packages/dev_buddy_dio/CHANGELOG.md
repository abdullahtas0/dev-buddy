# Changelog

## 0.1.0

### Added
- `DevBuddyDioInterceptor` for capturing HTTP request/response data from Dio
- Automatic request timing measurement
- Response size estimation
- Error capture with Dio exception type information
- Configurable `maxBodyPreviewLength` for response size estimation
- Bounded timestamp tracking with orphan cleanup to prevent memory leaks
- Full delegation to next interceptor in chain (non-breaking)
