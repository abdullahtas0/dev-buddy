# Contributing to DevBuddy

Thank you for your interest in contributing to DevBuddy!

## Getting Started

### Prerequisites
- Flutter SDK >= 3.10.0
- Dart SDK >= 3.11.3
- Melos (`dart pub global activate melos`)

### Setup

```bash
git clone https://github.com/abdullah017/dev_buddy.git
cd dev_buddy
melos bootstrap
```

### Running Tests

```bash
melos run test            # Run all tests
melos run test:coverage   # Run with coverage
```

### Linting

```bash
melos run analyze         # Dart analyzer
melos run format          # Check formatting
melos run format:fix      # Auto-fix formatting
melos run lint:all        # Both analyze + format
```

### Full CI Pipeline

```bash
melos run qualitycheck    # clean + bootstrap + lint + test
```

## Code Style

- Follow `package:lints/recommended.yaml` + custom rules in `analysis_options.yaml`
- Use `const` constructors wherever possible
- Prefer immutable data models
- Keep files under 400 lines (800 max)
- Functions under 50 lines
- No external dependencies in the core `dev_buddy` package

## Adding Error Patterns

To contribute new error patterns to `ErrorCatalog`:

1. Add the pattern to `_englishPatterns` in `packages/dev_buddy/lib/src/modules/error_translator/error_catalog.dart`
2. Include: regex pattern, severity, title builder, description builder, and 2-4 actionable suggestions
3. Add a test in `packages/dev_buddy/test/modules/error_translator/error_catalog_test.dart`

## Creating a Custom Module

Implement `DevBuddyModule`:

```dart
class MyModule extends DevBuddyModule {
  @override String get id => 'my_module';
  @override String get name => 'My Module';
  @override IconData get icon => Icons.extension;

  @override
  void initialize({required DevBuddyConfig config, required Function(DevBuddyEvent) onEvent}) {
    // Setup monitoring
  }

  @override
  void dispose() {
    // Cleanup
  }

  @override
  Widget buildTab(BuildContext context, List<DevBuddyEvent> events) {
    // Tab UI
  }
}
```

## Pull Request Process

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Make changes with tests
4. Run `melos run qualitycheck` to verify
5. Submit a PR with a clear description

### Commit Messages

Use conventional commits:
```
feat: add new error pattern for TimeoutException
fix: resolve memory leak in PerformanceModule
docs: update NetworkModule usage examples
test: add edge case tests for FrameAnalyzer
```

## Reporting Issues

Use [GitHub Issues](https://github.com/abdullah017/dev_buddy/issues) with:
- Flutter/Dart version
- DevBuddy version
- Steps to reproduce
- Expected vs actual behavior
