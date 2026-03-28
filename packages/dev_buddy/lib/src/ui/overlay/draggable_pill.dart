// packages/dev_buddy/lib/src/ui/overlay/draggable_pill.dart
import 'package:flutter/material.dart';
import '../../core/severity.dart';
import '../theme/dev_buddy_theme.dart';

/// Floating draggable pill that shows FPS and overall status color.
///
/// Sits in a [Stack] on top of the app content. Tapping opens the
/// diagnostic panel.
class DraggablePill extends StatefulWidget {
  final ValueNotifier<double> fps;
  final ValueNotifier<Severity> severity;
  final VoidCallback onTap;

  const DraggablePill({
    super.key,
    required this.fps,
    required this.severity,
    required this.onTap,
  });

  @override
  State<DraggablePill> createState() => _DraggablePillState();
}

class _DraggablePillState extends State<DraggablePill> {
  Offset _position = const Offset(16, 60);
  double _totalDragDistance = 0;

  /// Pill dimensions for bounds clamping.
  static const double _pillEstimatedWidth = 80;
  static const double _pillEstimatedHeight = 36;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        // Use pan exclusively - onTap conflicts with pan in gesture arena.
        // Distinguish tap vs drag by total distance moved.
        onPanStart: (_) {
          _totalDragDistance = 0;
        },
        onPanUpdate: (details) {
          _totalDragDistance += details.delta.distance;
          setState(() {
            _position = Offset(
              (_position.dx + details.delta.dx).clamp(
                0,
                screenSize.width - _pillEstimatedWidth,
              ),
              (_position.dy + details.delta.dy).clamp(
                0,
                screenSize.height - _pillEstimatedHeight,
              ),
            );
          });
        },
        onPanEnd: (_) {
          // If total movement < 10px, treat as a tap
          if (_totalDragDistance < 10) {
            widget.onTap();
          }
        },
        // Single merged listener replaces two nested ValueListenableBuilders,
        // reducing rebuild overhead from 2 builders to 1.
        child: ListenableBuilder(
          listenable: Listenable.merge([widget.severity, widget.fps]),
          builder: (context, _) {
            final severity = widget.severity.value;
            final fps = widget.fps.value;
            return Semantics(
              label: 'DevBuddy ${fps.round()} FPS',
              button: true,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: DevBuddyTheme.pillPadding,
                decoration: BoxDecoration(
                  color: DevBuddyTheme.colorForSeverity(severity),
                  borderRadius: BorderRadius.circular(
                    DevBuddyTheme.pillBorderRadius,
                  ),
                  boxShadow: const [DevBuddyTheme.pillShadow],
                ),
                child: Text(
                  '${fps.round()} FPS',
                  style: DevBuddyTheme.pillText,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
