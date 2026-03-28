# Changelog

## 0.1.0

### Added
- `DevBuddyHttpClient` wrapper for the `http` package
- Automatic request timing measurement
- Response size capture from streamed body
- Error capture with exception message forwarding
- Transparent delegation to inner `http.Client`
- Support for all HTTP methods (GET, POST, PUT, DELETE, PATCH, HEAD)
