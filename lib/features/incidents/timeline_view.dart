import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/enums.dart';
import '../../models/timeline_event.dart';

/// Polished vertical audit timeline.
class TimelineView extends StatelessWidget {
  const TimelineView(this.events, {super.key, this.showIncidentId = false});
  final List<TimelineEvent> events;
  final bool showIncidentId;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No events yet.', style: TextStyle(color: RgColors.muted)),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < events.length; i++) _row(events[i], first: i == 0, last: i == events.length - 1),
      ],
    );
  }

  Widget _row(TimelineEvent e, {required bool first, required bool last}) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 74,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(Fmt.time(e.timestamp),
                textAlign: TextAlign.right,
                style: AppTheme.mono.copyWith(fontSize: 11, color: RgColors.muted, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 28,
          child: Column(children: [
            Container(width: 2, height: 4, color: first ? Colors.transparent : RgColors.line),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: e.type.color.withValues(alpha: 0.18),
                border: Border.all(color: e.type.color),
              ),
              child: Icon(e.type.icon, size: 14, color: e.type.color),
            ),
            Expanded(child: Container(width: 2, color: last ? Colors.transparent : RgColors.line)),
          ]),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5, bottom: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (showIncidentId)
                Text(e.incidentId,
                    style: const TextStyle(fontSize: 10.5, color: RgColors.blue, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
              Text(e.message, style: const TextStyle(fontSize: 13.5, height: 1.3)),
            ]),
          ),
        ),
      ]),
    );
  }
}
