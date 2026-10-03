import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/enums.dart';
import '../../models/incident.dart';
import '../../services/incident_service.dart';
import '../../widgets/common.dart';
import '../admin/assign_sheet.dart';
import '../maps/campus_map.dart';
import '../maps/navigation_screen.dart';
import 'timeline_view.dart';

class IncidentDetailScreen extends StatelessWidget {
  const IncidentDetailScreen({super.key, required this.incidentId});
  final String incidentId;

  static Future<void> open(BuildContext context, String id) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => IncidentDetailScreen(incidentId: id)));

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RescueStore>();
    final inc = store.incident(incidentId);
    final user = store.currentUser;
    if (inc == null || user == null) {
      return const Scaffold(body: EmptyState('Incident not found'));
    }
    // Incident ownership: students may only open their own reports.
    if (user.role == UserRole.student && inc.reporterId != user.id) {
      return Scaffold(appBar: AppBar(), body: const EmptyState('You can only view incidents you reported.', icon: Icons.lock));
    }
    final responder = store.responderById(inc.assignedResponderId);
    final me = user.role == UserRole.responder ? store.responderForUser(user.id) : null;
    final isPrimary = me != null && me.id == inc.assignedResponderId;
    final isBackup = me != null && inc.backupResponderIds.contains(me.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(inc.id, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        actions: const [DemoModeBadge()],
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 120), children: [
        _Header(inc: inc),
        if (inc.escalated || inc.backupRequested) ...[
          const SizedBox(height: 12),
          Panel(
            color: RgColors.amber.withValues(alpha: 0.10),
            border: RgColors.amber,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (inc.escalated)
                const Text('⚠ ESCALATED — awaiting reassignment', style: TextStyle(color: RgColors.amber, fontWeight: FontWeight.w800)),
              if (inc.backupRequested) ...[
                Text('🚨 BACKUP REQUESTED: ${inc.backupReasons.join(', ')}',
                    style: const TextStyle(color: RgColors.amber, fontWeight: FontWeight.w800)),
                if (inc.recommendedBackupId != null)
                  Text('Recommended backup: ${store.responderById(inc.recommendedBackupId)?.name}',
                      style: const TextStyle(color: RgColors.text)),
                if (inc.backupResponderIds.isNotEmpty)
                  Text('Backup: ${inc.backupResponderIds.map((id) => '${store.responderById(id)?.name} (${store.responderById(id)?.status.label})').join(', ')}'),
              ],
            ]),
          ),
        ],
        const SizedBox(height: 12),
        _TrackingCard(inc: inc),
        if (inc.isActive) ...[
          const SizedBox(height: 12),
          CampusMap(focusIncidentId: inc.id, height: 240),
        ],
        const SectionTitle('Severity engine'),
        _SeverityCard(inc: inc),
        if (user.role != UserRole.student && inc.lastRanking.isNotEmpty) ...[
          const SectionTitle('Responder ranking'),
          _RankingCard(inc: inc),
        ],
        const SectionTitle('Report details'),
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _kv('Reporter', inc.reporterName),
            _kv('Location', 'LBRCE Campus · ${inc.locationName}'),
            if (inc.gps != null && inc.gps!.isReal) ...[
              _kv('Latitude', inc.gps!.latitude.toStringAsFixed(6)),
              _kv('Longitude', inc.gps!.longitude.toStringAsFixed(6)),
              _kv('Accuracy', '±${inc.gps!.accuracy.round()} m'),
            ] else
              _kv('GPS', 'SIMULATED CAMPUS LOCATION (no device GPS)'),
            _kv('People affected', inc.peopleAffected >= 5 ? '5+' : '${inc.peopleAffected}'),
            _kv('Reported', Fmt.dateTime(inc.createdAt)),
            if (responder != null) _kv('Responder', '${responder.name} · ${responder.type}'),
            if (inc.responseTime != null) _kv('Response time', Fmt.duration(inc.responseTime)),
            if (inc.resolutionTime != null) _kv('Resolution time', Fmt.duration(inc.resolutionTime)),
            if (inc.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('“${inc.description}”', style: const TextStyle(fontStyle: FontStyle.italic, height: 1.35)),
            ],
            if (inc.photoPath != null || inc.demoPhoto) ...[const SizedBox(height: 12), IncidentPhoto(inc)],
          ]),
        ),
        const SectionTitle('Incident timeline'),
        Panel(child: TimelineView(store.timeline(inc.id))),
        if (isBackup) ...[
          const SizedBox(height: 12),
          const Panel(child: Text('You are assigned as BACKUP on this incident.')),
        ],
      ]),
      bottomNavigationBar: inc.isActive
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: user.role == UserRole.admin
                    ? _AdminActions(inc: inc)
                    : isPrimary
                        ? _ResponderActions(inc: inc)
                        : const SizedBox.shrink(),
              ),
            )
          : null,
    );
  }

  static Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 120, child: Text(k, style: const TextStyle(color: RgColors.muted, fontSize: 13))),
          Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5))),
        ]),
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.inc});
  final Incident inc;
  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Row(children: [
        CategoryIcon(inc.category, size: 54, color: inc.severityLevel.color),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(inc.category.label.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: 0.8)),
            const SizedBox(height: 2),
            Text(inc.locationName, style: const TextStyle(color: RgColors.muted)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              SeverityBadge(inc.severityLevel, inc.severityScore, dense: true),
              StatusPill(inc.status, dense: true),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _TrackingCard extends StatelessWidget {
  const _TrackingCard({required this.inc});
  final Incident inc;
  @override
  Widget build(BuildContext context) {
    final store = context.watch<RescueStore>();
    final r = store.responderById(inc.assignedResponderId);
    final String headline;
    switch (inc.status) {
      case IncidentStatus.reported:
        headline = inc.escalated ? 'Finding an available responder…' : 'Ranking responders…';
      case IncidentStatus.assigned:
        headline = '${r?.name} assigned — awaiting acceptance';
      case IncidentStatus.accepted:
        headline = '${r?.name} accepted — preparing to move';
      case IncidentStatus.enRoute:
        headline = 'Responder is on the way.';
      case IncidentStatus.arrived:
        headline = 'Responder has arrived.';
      case IncidentStatus.onScene:
        headline = 'Responder on scene.';
      case IncidentStatus.resolved:
        headline = 'Incident resolved.';
    }
    final live = inc.status == IncidentStatus.enRoute;
    return Panel(
      border: live ? RgColors.blue : null,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (live) const PulseDot(color: RgColors.blue, size: 8),
          if (live) const SizedBox(width: 6),
          Expanded(child: Text(headline, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
        ]),
        if (r != null && inc.isActive) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _metric('RESPONDER', r.name)),
            Expanded(child: _metric('DISTANCE', Fmt.distance(inc.distanceM))),
            Expanded(child: _metric('ETA', Fmt.mmss(inc.etaSec))),
          ]),
          if (live)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Live tracking · simulated movement in DEMO MODE',
                  style: TextStyle(color: RgColors.muted, fontSize: 11)),
            ),
        ],
      ]),
    );
  }

  Widget _metric(String l, String v) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l, style: const TextStyle(color: RgColors.muted, fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(v, style: AppTheme.mono.copyWith(fontWeight: FontWeight.w900, fontSize: 17)),
      ]);
}

class _SeverityCard extends StatelessWidget {
  const _SeverityCard({required this.inc});
  final Incident inc;
  @override
  Widget build(BuildContext context) {
    final s = inc.severity;
    return Panel(
      border: s.level.color.withValues(alpha: 0.6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${s.score}', style: AppTheme.mono.copyWith(fontSize: 46, fontWeight: FontWeight.w900, color: s.level.color, height: 1)),
          const Text('/100', style: TextStyle(color: RgColors.muted, fontSize: 16)),
          const Spacer(),
          Pill('SEVERITY: ${s.level.label}', color: s.level.color),
        ]),
        const SizedBox(height: 14),
        for (final f in s.factors)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              SizedBox(width: 118, child: Text(f.label, style: const TextStyle(fontSize: 12.5, color: RgColors.muted))),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: f.max == 0 ? 0 : f.points / f.max,
                    minHeight: 8,
                    backgroundColor: RgColors.panelHi,
                    color: s.level.color,
                  ),
                ),
              ),
              SizedBox(
                  width: 52,
                  child: Text('${f.points}/${f.max}', textAlign: TextAlign.right, style: AppTheme.mono.copyWith(fontSize: 12))),
            ]),
          ),
        const SizedBox(height: 6),
        const Text('WHY?', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.4, fontSize: 12)),
        const SizedBox(height: 6),
        for (final r in s.reasons)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('✓ $r', style: const TextStyle(fontSize: 13.5)),
          ),
        Text('✓ ${s.action}', style: TextStyle(fontSize: 13.5, color: s.level.color, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('Rule-based, explainable scoring — not a machine-learning model.',
            style: TextStyle(color: RgColors.muted, fontSize: 11)),
      ]),
    );
  }
}

class _RankingCard extends StatelessWidget {
  const _RankingCard({required this.inc});
  final Incident inc;
  @override
  Widget build(BuildContext context) {
    final list = inc.lastRanking.take(3).toList();
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (var i = 0; i < list.length; i++) ...[
          if (i == 0)
            const Text('RECOMMENDED RESPONDER',
                style: TextStyle(color: RgColors.green, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 11.5)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Text('${i + 1}', style: AppTheme.mono.copyWith(fontSize: 22, fontWeight: FontWeight.w900, color: RgColors.muted)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(list[i].responder.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(
                      'Skill Match: ${(list[i].skillMatch * 100).round()}% · ETA: ${(list[i].etaSec / 60).ceil()} min · '
                      'Workload: ${list[i].responder.workload}',
                      style: const TextStyle(fontSize: 12, color: RgColors.muted)),
                ]),
              ),
              Text(list[i].total.round().toString(),
                  style: AppTheme.mono.copyWith(fontSize: 18, fontWeight: FontWeight.w900, color: i == 0 ? RgColors.green : RgColors.text)),
            ]),
          ),
        ],
      ]),
    );
  }
}

// ---------------------------------------------------------------- actions

class _ResponderActions extends StatelessWidget {
  const _ResponderActions({required this.inc});
  final Incident inc;

  @override
  Widget build(BuildContext context) {
    final store = context.read<RescueStore>();
    final primary = switch (inc.status) {
      IncidentStatus.assigned => Row(children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: RgColors.red, minimumSize: const Size.fromHeight(52)),
              onPressed: () => showDeclineDialog(context, inc.id),
              child: const Text('DECLINE'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _big('ACCEPT', RgColors.green, () {
              store.accept(inc.id);
              showMsg(context, 'Assignment accepted. Navigation enabled.');
            }),
          ),
        ]),
      IncidentStatus.accepted => _big('START ROUTE · NAVIGATE', RgColors.blue, () {
          store.startRoute(inc.id);
          Navigator.push(context, MaterialPageRoute<void>(builder: (_) => NavigationScreen(incidentId: inc.id)));
        }),
      IncidentStatus.enRoute => Row(children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: () =>
                  Navigator.push(context, MaterialPageRoute<void>(builder: (_) => NavigationScreen(incidentId: inc.id))),
              child: const Text('NAVIGATION'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: _big('ARRIVED', RgColors.green, () => store.markArrived(inc.id))),
        ]),
      IncidentStatus.arrived => _big('ON SCENE', RgColors.amber, () => store.markOnScene(inc.id)),
      IncidentStatus.onScene => _big('RESOLVE INCIDENT', RgColors.green, () {
          guarded(context, () => store.resolve(inc.id), success: 'Incident ${inc.id} resolved');
        }),
      _ => const SizedBox.shrink(),
    };
    return Column(mainAxisSize: MainAxisSize.min, children: [
      primary,
      if (inc.status != IncidentStatus.assigned) ...[
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: RgColors.red),
            icon: const Icon(Icons.group_add),
            label: Text(inc.backupRequested ? 'BACKUP REQUESTED · REQUEST AGAIN' : '🚨 REQUEST BACKUP'),
            onPressed: () => showBackupDialog(context, inc.id),
          ),
        ),
      ],
    ]);
  }

  Widget _big(String text, Color c, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(backgroundColor: c, minimumSize: const Size.fromHeight(52)),
          onPressed: onTap,
          child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
      );
}

class _AdminActions extends StatelessWidget {
  const _AdminActions({required this.inc});
  final Incident inc;
  @override
  Widget build(BuildContext context) {
    final store = context.read<RescueStore>();
    return Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
      FilledButton.tonal(
        onPressed: () => showAssignSheet(context, inc.id),
        child: Text(inc.assignedResponderId == null ? 'ASSIGN' : 'REASSIGN'),
      ),
      if (inc.backupRequested)
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: RgColors.amber, foregroundColor: Colors.black),
          onPressed: () => showAssignSheet(context, inc.id, backup: true),
          child: const Text('ASSIGN BACKUP'),
        ),
      OutlinedButton(
        onPressed: () => guarded(context, () => store.escalate(inc.id, reason: 'Escalated manually by command center'),
            success: 'Incident escalated'),
        child: const Text('ESCALATE'),
      ),
      FilledButton(
        style: FilledButton.styleFrom(backgroundColor: RgColors.green),
        onPressed: () => guarded(context, () => store.resolve(inc.id), success: 'Incident resolved'),
        child: const Text('RESOLVE'),
      ),
    ]);
  }
}

Future<void> showDeclineDialog(BuildContext context, String incidentId) async {
  const reasons = ['Busy', 'Wrong skill', 'Off duty', 'Other'];
  final picked = await showDialog<String>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('Decline assignment — reason'),
      children: [
        for (final r in reasons)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, r),
            child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(r)),
          ),
      ],
    ),
  );
  if (picked == null || !context.mounted) return;
  context.read<RescueStore>().decline(incidentId, picked);
  showMsg(context, 'Assignment declined. Next eligible responder is being assigned.');
  Navigator.of(context).maybePop();
}

Future<void> showBackupDialog(BuildContext context, String incidentId) async {
  const options = ['Medical assistance', 'Additional security', 'Crowd control', 'Equipment required', 'Fire support', 'Other'];
  final selected = <String>{};
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Backup Required'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final o in options)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: selected.contains(o),
                title: Text(o),
                onChanged: (v) => setState(() => v == true ? selected.add(o) : selected.remove(o)),
              ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: RgColors.red),
            onPressed: selected.isEmpty ? null : () => Navigator.pop(ctx, true),
            child: const Text('REQUEST BACKUP'),
          ),
        ],
      ),
    ),
  );
  if (ok != true || !context.mounted) return;
  context.read<RescueStore>().requestBackup(incidentId, selected.toList());
  showMsg(context, 'Backup requested. Command center notified.');
}
