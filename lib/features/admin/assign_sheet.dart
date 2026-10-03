import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/enums.dart';
import '../../services/incident_service.dart';
import '../../widgets/common.dart';

/// Ranked responder list with manual ASSIGN (or ASSIGN AS BACKUP) override.
Future<void> showAssignSheet(BuildContext context, String incidentId, {bool backup = false}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: RgColors.panel,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => _AssignList(incidentId: incidentId, backup: backup, scroll: scroll),
    ),
  );
}

class _AssignList extends StatelessWidget {
  const _AssignList({required this.incidentId, required this.backup, required this.scroll});
  final String incidentId;
  final bool backup;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RescueStore>();
    final inc = store.incident(incidentId);
    if (inc == null) return const EmptyState('Incident not found');
    final ranking = store.rankFor(inc);
    return ListView(controller: scroll, padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
      Center(
        child: Container(
            width: 40, height: 4, decoration: BoxDecoration(color: RgColors.line, borderRadius: BorderRadius.circular(4))),
      ),
      const SizedBox(height: 14),
      Text(backup ? 'ASSIGN BACKUP · ${inc.id}' : 'AVAILABLE RESPONDERS · ${inc.id}',
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
      const SizedBox(height: 4),
      Text('Ranked by skill ${store.weights.skill}% · ETA ${store.weights.eta}% · availability ${store.weights.availability}% · workload ${store.weights.workload}%',
          style: const TextStyle(color: RgColors.muted, fontSize: 12)),
      const SizedBox(height: 12),
      for (var i = 0; i < ranking.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Panel(
            border: i == 0 && ranking[i].eligible ? RgColors.green : null,
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(ranking[i].responder.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(width: 8),
                    ResponderStatusPill(ranking[i].responder.status, dense: true),
                  ]),
                  const SizedBox(height: 4),
                  Text(ranking[i].responder.skillsLabel, style: const TextStyle(color: RgColors.muted, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(
                    'Score ${ranking[i].total.round()} · Skill ${(ranking[i].skillMatch * 100).round()}% · '
                    'ETA ${(ranking[i].etaSec / 60).ceil()} min · Workload ${ranking[i].responder.workload}',
                    style: AppTheme.mono.copyWith(fontSize: 12),
                  ),
                  if (ranking[i].note != null)
                    Text(ranking[i].note!, style: const TextStyle(color: RgColors.amber, fontSize: 11.5)),
                ]),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: !ranking[i].eligible && !(ranking[i].note?.startsWith('Declined') ?? false)
                    ? null
                    : () {
                        guarded(context, () {
                          if (backup) {
                            store.assignBackup(inc.id, ranking[i].responder.id);
                          } else {
                            store.manualAssign(inc.id, ranking[i].responder.id);
                          }
                        }, success: '${ranking[i].responder.name} assigned');
                        Navigator.pop(context);
                      },
                child: const Text('ASSIGN'),
              ),
            ]),
          ),
        ),
      if (ranking.every((r) => !r.eligible))
        const Text('No responders are currently available.', style: TextStyle(color: RgColors.amber)),
      if (inc.status == IncidentStatus.resolved) const Text('Incident already resolved.'),
    ]);
  }
}
