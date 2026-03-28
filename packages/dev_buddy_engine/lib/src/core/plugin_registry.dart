import 'plugin.dart';

/// Exception thrown when plugin dependencies are not satisfied.
class PluginDependencyException implements Exception {
  final String pluginId;
  final List<String> missingDependencies;

  const PluginDependencyException({
    required this.pluginId,
    required this.missingDependencies,
  });

  @override
  String toString() =>
      'PluginDependencyException: Plugin "$pluginId" requires '
      'plugins [${missingDependencies.join(', ')}] which are not registered.';
}

/// Exception thrown when a plugin with a duplicate ID is registered.
class DuplicatePluginException implements Exception {
  final String pluginId;

  const DuplicatePluginException(this.pluginId);

  @override
  String toString() =>
      'DuplicatePluginException: Plugin "$pluginId" is already registered.';
}

/// Registry for managing [DevBuddyPlugin] instances.
///
/// Handles registration, lookup, dependency validation, and lifecycle.
class PluginRegistry {
  final Map<String, DevBuddyPlugin> _plugins = {};

  /// All registered plugins (read-only).
  List<DevBuddyPlugin> get all => List.unmodifiable(_plugins.values.toList());

  /// Number of registered plugins.
  int get length => _plugins.length;

  /// Register a plugin. Throws [DuplicatePluginException] if ID already exists.
  void register(DevBuddyPlugin plugin) {
    if (_plugins.containsKey(plugin.id)) {
      throw DuplicatePluginException(plugin.id);
    }
    _plugins[plugin.id] = plugin;
  }

  /// Look up a plugin by type. Returns null if not found.
  T? get<T extends DevBuddyPlugin>() {
    for (final plugin in _plugins.values) {
      if (plugin is T) return plugin;
    }
    return null;
  }

  /// Look up a plugin by ID. Returns null if not found.
  DevBuddyPlugin? getById(String id) => _plugins[id];

  /// Check if a plugin with the given ID is registered.
  bool has(String id) => _plugins.containsKey(id);

  /// Validate that all registered plugins have their dependencies satisfied.
  ///
  /// Throws [PluginDependencyException] for the first plugin with unmet deps.
  void validateDependencies() {
    for (final plugin in _plugins.values) {
      final missing = plugin.dependencies
          .where((depId) => !_plugins.containsKey(depId))
          .toList();
      if (missing.isNotEmpty) {
        throw PluginDependencyException(
          pluginId: plugin.id,
          missingDependencies: missing,
        );
      }
    }
  }

  /// Dispose all plugins in reverse registration order.
  void disposeAll() {
    for (final plugin in _plugins.values.toList().reversed) {
      plugin.onDispose();
    }
    _plugins.clear();
  }
}
