# DevBuddy

Human-Readable Flutter Diagnostics -- Not Metrics, Solutions.

This is the monorepo for the DevBuddy Flutter packages, managed with [Melos](https://melos.invertase.dev/).

## Packages

| Package | Description | pub.dev |
|---------|-------------|---------|
| [dev_buddy](packages/dev_buddy/) | Core diagnostics overlay with 5 built-in modules | [![pub package](https://img.shields.io/pub/v/dev_buddy.svg)](https://pub.dev/packages/dev_buddy) |
| [dev_buddy_dio](packages/dev_buddy_dio/) | Dio HTTP client adapter for network monitoring | [![pub package](https://img.shields.io/pub/v/dev_buddy_dio.svg)](https://pub.dev/packages/dev_buddy_dio) |
| [dev_buddy_http](packages/dev_buddy_http/) | http package adapter for network monitoring | [![pub package](https://img.shields.io/pub/v/dev_buddy_http.svg)](https://pub.dev/packages/dev_buddy_http) |

## Documentation

See [packages/dev_buddy/README.md](packages/dev_buddy/README.md) for full documentation, quick start guide, and API reference.

## Development

```bash
# Install Melos globally
dart pub global activate melos

# Bootstrap all packages
melos bootstrap

# Run all tests
melos run test

# Run full CI pipeline (clean, bootstrap, lint, test)
melos run qualitycheck
```

## License

MIT License. See [LICENSE](LICENSE) for details.
