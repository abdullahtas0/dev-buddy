import 'engine.dart';

/// Extension point for community-created diagnostic plugins.
///
/// Plugins are registered with [DevBuddyEngine] via [PluginRegistry].
/// They receive the engine instance on registration and can:
/// - Listen to events via [engine.eventBus]
/// - Access module states
/// - Provide their own diagnostic data via [currentState]
///
/// Example:
/// ```dart
/// class SharedPrefsPlugin extends DevBuddyPlugin {
///   @override String get id => 'shared_prefs';
///   @override String get displayName => 'SharedPreferences';
///   @override String get version => '1.0.0';
///
///   @override
///   void onRegister(DevBuddyEngine engine) {
///     // Set up inspection logic
///   }
///
///   @override
///   void onDispose() { /* cleanup */ }
///
///   @override
///   Map<String, dynamic> get currentState => {'entries': 42};
/// }
/// ```
abstract class DevBuddyPlugin {
  /// Unique identifier. Convention: lowercase with underscores (e.g., 'shared_prefs').
  String get id;

  /// Human-readable name shown in UI and MCP responses.
  String get displayName;

  /// Semantic version string (e.g., '1.0.0').
  String get version;

  /// Plugin IDs that must be registered before this plugin.
  /// The registry validates these during [PluginRegistry.validateDependencies].
  List<String> get dependencies => const [];

  /// Called when the plugin is registered with the engine.
  /// Use this to set up event listeners, timers, etc.
  void onRegister(DevBuddyEngine engine);

  /// Called when the engine is being disposed.
  /// Clean up any resources created in [onRegister].
  void onDispose();

  /// Current plugin state as a serializable map.
  /// Used by MCP server and DevTools extension.
  Map<String, dynamic> get currentState;
}
