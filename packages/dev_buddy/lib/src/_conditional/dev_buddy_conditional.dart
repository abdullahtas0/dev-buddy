// packages/dev_buddy/lib/src/_conditional/dev_buddy_conditional.dart
//
// Conditional import bridge: selects real implementation in debug/profile
// and no-op implementation in release builds.
//
// In release, dart:developer is not available, so the noop path is taken.
// This ensures DevBuddy compiles to zero bytes in release via tree-shaking.

export 'dev_buddy_noop.dart'
    if (dart.library.developer) 'dev_buddy_real.dart';
