// packages/dev_buddy/lib/src/ui/panel/dev_buddy_panel.dart
import 'package:flutter/material.dart';
import '../../core/dev_buddy_controller.dart';
import '../../i18n/strings.dart';
import '../theme/dev_buddy_theme.dart';
import 'module_tab_view.dart';

/// Bottom sheet panel showing module tabs and diagnostic events.
///
/// Features:
/// - Animated slide-up transition when opening
/// - TabBar with one tab per registered module (icon + name)
/// - Each tab delegates to module.buildTab(context, filteredEvents)
/// - "Clear All" and "Export" buttons in the header
/// - Apple-style design: clean, minimal, generous spacing
class DevBuddyPanel extends StatefulWidget {
  final DevBuddyController controller;
  final VoidCallback onClose;
  final VoidCallback? onExport;

  const DevBuddyPanel({
    super.key,
    required this.controller,
    required this.onClose,
    this.onExport,
  });

  @override
  State<DevBuddyPanel> createState() => _DevBuddyPanelState();
}

class _DevBuddyPanelState extends State<DevBuddyPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      ),
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _handleClearAll() {
    widget.controller.clearEvents();
  }

  void _handleExport() {
    widget.onExport?.call();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final brightness = Theme.of(context).brightness;
    final strings = DevBuddyStrings.fromLocale(widget.controller.config.locale);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          elevation: 8,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(DevBuddyTheme.panelBorderRadius),
          ),
          color: DevBuddyTheme.panelBackgroundFor(brightness),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: screenHeight * DevBuddyTheme.panelMaxHeight,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: brightness == Brightness.dark
                          ? DevBuddyTheme.handleBarColorDark
                          : DevBuddyTheme.handleBarColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header with title and action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        strings.panelTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      // Export button
                      _HeaderButton(
                        icon: Icons.ios_share,
                        label: strings.export,
                        onTap: _handleExport,
                        brightness: brightness,
                      ),
                      const SizedBox(width: 8),
                      // Clear all button
                      _HeaderButton(
                        icon: Icons.delete_outline,
                        label: strings.clearAll,
                        onTap: _handleClearAll,
                        brightness: brightness,
                      ),
                      const SizedBox(width: 4),
                      // Close button
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: widget.onClose,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // Module tabs + content
                Flexible(
                  child: ModuleTabView(
                    controller: widget.controller,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A small, Apple-style header action button.
class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Brightness brightness;

  const _HeaderButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = DevBuddyTheme.headerButtonBackgroundFor(brightness);
    final textColor = DevBuddyTheme.headerButtonTextFor(brightness);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
