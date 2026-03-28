# Changelog

## 0.2.0

### Changed
- Depends on `dev_buddy_engine` instead of `dev_buddy` (pure Dart, no Flutter dependency)
- Request ID now uses atomic counter instead of hashCode (prevents collisions)
- Header/body capture with configurable `captureHeaders` and `captureBody` flags
- Orphaned request cleanup with 5-minute threshold

## 0.1.0

### Added
- `DevBuddyDioInterceptor` for capturing HTTP request/response data from Dio
- Automatic request timing measurement
- Response size estimation
- Error capture with Dio exception type information
- Configurable `maxBodyPreviewLength` for response size estimation
- Bounded timestamp tracking with orphan cleanup to prevent memory leaks
- Full delegation to next interceptor in chain (non-breaking)
