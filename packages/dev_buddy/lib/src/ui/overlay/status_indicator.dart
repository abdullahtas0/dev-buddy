// packages/dev_buddy/lib/src/ui/overlay/status_indicator.dart
import 'package:flutter/material.dart';
import '../../core/severity.dart';
import '../theme/dev_buddy_theme.dart';

/// Animated color indicator dot that reflects overall severity.
class StatusIndicator extends StatelessWidget {
  final Severity severity;
  final double size;

  const StatusIndicator({super.key, required this.severity, this.size = 8.0});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: DevBuddyTheme.colorForSeverity(severity),
        boxShadow: [
          BoxShadow(
            color: DevBuddyTheme.colorForSeverity(
              severity,
            ).withValues(alpha: 0.4),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}
