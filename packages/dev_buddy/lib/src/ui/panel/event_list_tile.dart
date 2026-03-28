// packages/dev_buddy/lib/src/ui/panel/event_list_tile.dart
import 'package:flutter/material.dart';
import '../../core/dev_buddy_event.dart';
import '../theme/dev_buddy_theme.dart';

/// A reusable tile widget for displaying a single [DevBuddyEvent].
///
/// Shows severity emoji, title, description, and actionable suggestions
/// with a lightbulb icon. Apple-style: clean, minimal, generous spacing.
class EventListTile extends StatelessWidget {
  final DevBuddyEvent event;

  const EventListTile({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: DevBuddyTheme.colorForSeverity(event.severity),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Severity emoji + title row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.severity.emoji,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  event.title,
                  style: DevBuddyTheme.eventTitle,
                ),
              ),
            ],
          ),

          // Description
          if (event.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                event.description,
                style: DevBuddyTheme.eventDescription,
              ),
            ),
          ],

          // Suggestions with lightbulb icon
          if (event.suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...event.suggestions.map(
              (suggestion) => Padding(
                padding: const EdgeInsets.only(left: 24, top: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      size: 14,
                      color: Color(0xFF1E88E5),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: DevBuddyTheme.suggestionText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
