# Changelog

## 0.2.0

### Changed
- Depends on `dev_buddy_engine` instead of `dev_buddy` (pure Dart, no Flutter dependency)
- Added `maxCaptureBytes` threshold (10MB default) — large responses pass through without buffering
- Streaming-safe: responses above threshold are not read into memory
- Fixed `contentLength` accuracy in re-wrapped StreamedResponse

## 0.1.0

### Added
- `DevBuddyHttpClient` wrapper for the `http` package
- Automatic request timing measurement
- Response size capture from streamed body
- Error capture with exception message forwarding
- Transparent delegation to inner `http.Client`
- Support for all HTTP methods (GET, POST, PUT, DELETE, PATCH, HEAD)
