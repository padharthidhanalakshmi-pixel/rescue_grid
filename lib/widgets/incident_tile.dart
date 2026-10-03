import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../features/incidents/incident_detail_screen.dart';
import '../models/enums.dart';
import '../models/incident.dart';
import '../services/incident_service.dart';
import 'common.dart';

/// Compact incident card used in lists across all roles.
class IncidentTile extends StatelessWidget {
  const IncidentTile(this.inc, {super.key, this.showActions = false, this.trailing});
  final Incident inc;
  final bool showActions;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RescueStore>();
    final r = store.responderById(inc.assignedResponderId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Panel(
        border: inc.escalated
            ? RgColors.amber
            : (inc.isActive && inc.severityLevel == SeverityLevel.critical ? RgColors.red.withValues(alpha: 0.7) : null),
        onTap: () => IncidentDetailScreen.open(context, inc.id),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CategoryIcon(inc.category, size: 40, color: inc.severityLevel.color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(inc.id, style: AppTheme.mono.copyWith(fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                  const SizedBox(width: 8),
                  if (inc.escalated) const Pill('ESCALATED', color: RgColors.amber, dense: true),
                  if (inc.backupRequested && inc.isActive) ...[
                    const SizedBox(width: 4),
                    const Pill('BACKUP', color: RgColors.red, dense: true),
                  ],
                ]),
                Text(inc.category.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('Location: ${inc.locationName}', style: const TextStyle(color: RgColors.muted, fontSize: 12.5)),
              ]),
            ),
            if (trailing != null) trailing!,
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
            SeverityBadge(inc.severityLevel, inc.severityScore, dense: true),
            StatusPill(inc.status, dense: true),
            if (r != null) Pill(r.name, color: RgColors.blue, dense: true, icon: Icons.person),
            if (inc.isActive && r != null && inc.status.index <= IncidentStatus.enRoute.index)
              Pill('ETA ${Fmt.mmss(inc.etaSec)}', color: RgColors.text, dense: true),
            if (!inc.isActive) Pill(Fmt.dateTime(inc.createdAt), color: RgColors.muted, dense: true),
          ]),
        ]),
      ),
    );
  }
}
