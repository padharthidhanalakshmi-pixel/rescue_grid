import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/enums.dart';
import '../../models/incident.dart';
import '../../services/demo_orchestrator.dart';
import '../../services/incident_service.dart';
import '../../widgets/common.dart';
import '../../widgets/incident_tile.dart';
import '../incidents/incident_detail_screen.dart';
import '../incidents/timeline_view.dart';
import '../maps/campus_map.dart';
import '../notifications/notifications_screen.dart';
import 'analytics_screen.dart';
import 'assign_sheet.dart';
import 'settings_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _tab = 0;

  static const _dest = [
    (Icons.space_dashboard_outlined, Icons.space_dashboard, 'Command'),
    (Icons.warning_amber_outlined, Icons.warning_amber, 'Incidents'),
    (Icons.groups_outlined, Icons.groups, 'Responders'),
    (Icons.insights_outlined, Icons.insights, 'Analytics'),
    (Icons.timeline_outlined, Icons.timeline, 'Timeline'),
    (Icons.settings_outlined, Icons.settings, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      const CommandCenter(),
      const AdminIncidents(),
      const RespondersView(),
      const AnalyticsView(),
      const AuditTimelineView(),
      const SettingsView(),
    ];
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final body = KeyedSubtree(key: ValueKey(_tab), child: pages[_tab]);
    return Scaffold(
      appBar: AppBar(
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('RESCUEGRID', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
          Text(Brand.commandCenter,
              style: TextStyle(fontSize: 11, color: RgColors.red, letterSpacing: 1.6, fontWeight: FontWeight.w800)),
        ]),
        actions: [
          const DemoModeBadge(),
          NotificationBell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                  builder: (_) => Scaffold(appBar: AppBar(title: const Text('Notifications')), body: const NotificationsView())),
            ),
          ),
          IconButton(
            tooltip: 'Sign out / switch role',
            onPressed: context.read<RescueStore>().logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: wide
          ? Row(children: [
              NavigationRail(
                selectedIndex: _tab,
                onDestinationSelected: (i) => setState(() => _tab = i),
                labelType: NavigationRailLabelType.all,
                backgroundColor: RgColors.panel,
                destinations: [
                  for (final d in _dest)
                    NavigationRailDestination(icon: Icon(d.$1), selectedIcon: Icon(d.$2), label: Text(d.$3)),
                ],
              ),
              Expanded(child: body),
            ])
          : body,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _tab,
              labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
              onDestinationSelected: (i) => setState(() => _tab = i),
              destinations: [
                for (final d in _dest) NavigationDestination(icon: Icon(d.$1), selectedIcon: Icon(d.$2), label: d.$3),
              ],
            ),
    );
  }
}

// =============================================================== COMMAND CENTER

class CommandCenter extends StatelessWidget {
  const CommandCenter({super.key});

  static DemoOrchestrator? _orchestrator;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RescueStore>();
    final active = store.activeIncidents;
    final critical = active.where((i) => i.severityLevel == SeverityLevel.critical).length;
    final available = store.responders.values.where((r) => r.status == ResponderStatus.available).length;
    final pending = active.where((i) => i.status == IncidentStatus.assigned || i.status == IncidentStatus.reported).length;
    final escalated = active.where((i) => i.escalated || i.backupRequested).toList();
    final today = DateTime.now();
    final resolvedToday = store.resolvedIncidents
        .where((i) => i.resolvedAt != null && i.resolvedAt!.day == today.day && i.resolvedAt!.month == today.month)
        .length;
    final onScene = store.responders.values.where((r) => r.status == ResponderStatus.onScene).length;

    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Campus Emergency Operations',
          style: TextStyle(color: RgColors.muted, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
      Text(Brand.collegeName, style: const TextStyle(fontSize: 12, color: RgColors.muted)),
      const SizedBox(height: 12),
      _DemoPanel(store: store),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth > 700 ? 4 : 2;
        final cards = [
          StatCard(label: 'Active incidents', value: active.length.toString().padLeft(2, '0'), color: RgColors.text, icon: Icons.sensors),
          StatCard(label: 'Critical', value: critical.toString().padLeft(2, '0'), color: RgColors.red, icon: Icons.local_fire_department),
          StatCard(label: 'Available responders', value: available.toString().padLeft(2, '0'), color: RgColors.green, icon: Icons.groups),
          StatCard(label: 'Avg response time', value: Fmt.duration(store.averageResponse), color: RgColors.blue, icon: Icons.timer),
          StatCard(label: 'Pending assignments', value: '$pending', color: RgColors.amber),
          StatCard(label: 'Escalated', value: '${escalated.length}', color: RgColors.amber),
          StatCard(label: 'Resolved today', value: '$resolvedToday', color: RgColors.green),
          StatCard(label: 'Responders on scene', value: '$onScene'),
        ];
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.9,
          children: cards,
        );
      }),
      if (escalated.isNotEmpty) ...[
        const SectionTitle('⚠ Escalation required', trailing: PulseDot(color: RgColors.amber, size: 7)),
        for (final i in escalated) _EscalationCard(inc: i),
      ],
      const SectionTitle('Live campus map'),
      CampusMap(height: 320, onIncidentTap: (id) => IncidentDetailScreen.open(context, id)),
      const SectionTitle('Live incidents'),
      if (active.isEmpty) const EmptyState('No active incidents. Campus is clear.', icon: Icons.verified_user),
      for (final i in active) _AdminIncidentCard(inc: i),
      const BrandFooter(),
    ]);
  }
}

class _DemoPanel extends StatelessWidget {
  const _DemoPanel({required this.store});
  final RescueStore store;

  @override
  Widget build(BuildContext context) {
    if (store.demoRunning) {
      return Panel(
        border: RgColors.red,
        color: RgColors.red.withValues(alpha: 0.10),
        child: Row(children: [
          const PulseDot(),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('LIVE DEMO RUNNING', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.4, color: RgColors.red)),
              const SizedBox(height: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(store.demoStep ?? '…', key: ValueKey(store.demoStep), style: const TextStyle(fontSize: 15)),
              ),
            ]),
          ),
          TextButton(onPressed: () => CommandCenter._orchestrator?.cancel(), child: const Text('STOP')),
        ]),
      );
    }
    if (!store.demoMode) return const SizedBox.shrink();
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(
            child: Text('DEMO CONTROLS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.4, fontSize: 12)),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: RgColors.red),
            icon: const Icon(Icons.play_arrow),
            label: const Text('START LIVE DEMO'),
            onPressed: () async {
              final o = DemoOrchestrator(store);
              CommandCenter._orchestrator = o;
              final inc = await o.run();
              if (inc != null && context.mounted && inc.status == IncidentStatus.resolved) {
                IncidentDetailScreen.open(context, inc.id);
              }
            },
          ),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _chip(context, 'Reset Demo Data', Icons.restart_alt, () {
            store.resetDemo();
            showMsg(context, 'Demo data reset.');
          }),
          _chip(context, 'Simulate Emergency', Icons.add_alert, () => _simulateEmergency(context)),
          _chip(context, 'Simulate Assignment', Icons.assignment_ind, () => _simulateAssignment(context)),
          _chip(context, 'Simulate Responder Movement', Icons.directions_run, () => _simulateMovement(context)),
          _chip(context, 'Simulate Notification', Icons.notifications_active, () {
            store.notifications.deliver(
              title: '🚨 Test notification',
              body: 'RescueGrid in-app notification center is working (demo).',
              toRole: UserRole.admin,
            );
            store.updateSettings(() {});
          }),
        ]),
      ]),
    );
  }

  Widget _chip(BuildContext context, String label, IconData icon, VoidCallback onTap) =>
      ActionChip(avatar: Icon(icon, size: 16), label: Text(label), onPressed: onTap);

  void _simulateEmergency(BuildContext context) {
    final rnd = math.Random();
    final students = store.users.values.where((u) => u.role == UserRole.student).toList();
    const samples = {
      IncidentCategory.medical: 'Student fainted and is not responding',
      IncidentCategory.fire: 'Smoke coming from the room',
      IncidentCategory.security: 'Fight between two groups',
      IncidentCategory.electrical: 'Sparks from a switch board',
      IncidentCategory.accident: 'Bike slipped, rider injured',
      IncidentCategory.flooding: 'Water leak flooding the corridor',
      IncidentCategory.chemical: 'Strong chemical smell in lab',
      IncidentCategory.other: 'Crowd panic near the entrance',
    };
    final cat = IncidentCategory.values[rnd.nextInt(IncidentCategory.values.length)];
    final inc = store.reportIncident(
      reporter: students[rnd.nextInt(students.length)],
      category: cat,
      description: samples[cat]!,
      peopleAffected: 1 + rnd.nextInt(5),
      location: store.locations[rnd.nextInt(store.locations.length)],
      demoPhoto: true,
    );
    showMsg(context, 'Simulated ${inc.id}: ${cat.label} — ${inc.severityLevel.label} ${inc.severityScore}/100');
  }

  void _simulateAssignment(BuildContext context) {
    final waiting = store.activeIncidents.where((i) => i.assignedResponderId == null).toList();
    if (waiting.isEmpty) {
      showMsg(context, 'All active incidents already have a responder.');
      return;
    }
    final inc = waiting.first;
    final ranked = store.rankFor(inc).where((r) => r.eligible || r.note == 'Declined / no response').toList();
    if (ranked.isEmpty) {
      showMsg(context, 'No responders are currently available.');
      return;
    }
    guarded(context, () => store.manualAssign(inc.id, ranked.first.responder.id),
        success: '${ranked.first.responder.name} assigned to ${inc.id}');
  }

  void _simulateMovement(BuildContext context) {
    var started = 0;
    for (final i in store.activeIncidents) {
      if (i.status == IncidentStatus.assigned) store.accept(i.id);
      if (i.status == IncidentStatus.accepted) {
        store.startRoute(i.id);
        started++;
      } else if (i.status == IncidentStatus.enRoute && !i.trackingActive) {
        store.updateSettings(() => i.trackingActive = true);
        started++;
      }
    }
    store.updateSettings(() => store.simulateMovement = true);
    showMsg(context, started == 0 ? 'No responders to move.' : 'Simulating movement for $started responder(s).');
  }
}

class _EscalationCard extends StatelessWidget {
  const _EscalationCard({required this.inc});
  final Incident inc;
  @override
  Widget build(BuildContext context) {
    final store = context.read<RescueStore>();
    final rec = store.responderById(inc.recommendedBackupId);
    final reason = inc.backupRequested
        ? 'Backup requested: ${inc.backupReasons.join(', ')}'
        : (inc.assignedResponderId == null ? 'Responder did not accept / none available.' : 'Escalated by command center.');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Panel(
        border: RgColors.amber,
        color: RgColors.amber.withValues(alpha: 0.08),
        onTap: () => IncidentDetailScreen.open(context, inc.id),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('⚠ ${inc.id} · ${inc.category.label}', style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('Reason: $reason', style: const TextStyle(fontSize: 13)),
          Text(
              rec != null
                  ? 'Action: ${rec.name} recommended as backup.'
                  : inc.assignedResponderId == null
                      ? 'Action: next responder recommended.'
                      : 'Action: monitor.',
              style: const TextStyle(fontSize: 13, color: RgColors.amber)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            if (rec != null)
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: RgColors.amber, foregroundColor: Colors.black),
                onPressed: () => guarded(context, () => store.assignBackup(inc.id, rec.id), success: '${rec.name} assigned as backup'),
                child: Text('ASSIGN ${rec.name.toUpperCase()}'),
              ),
            OutlinedButton(
              onPressed: () => showAssignSheet(context, inc.id, backup: inc.backupRequested && inc.assignedResponderId != null),
              child: const Text('CHOOSE RESPONDER'),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _AdminIncidentCard extends StatelessWidget {
  const _AdminIncidentCard({required this.inc});
  final Incident inc;
  @override
  Widget build(BuildContext context) {
    final store = context.read<RescueStore>();
    return Column(children: [
      IncidentTile(inc),
      Transform.translate(
        offset: const Offset(0, -8),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Wrap(spacing: 4, children: [
            TextButton(onPressed: () => IncidentDetailScreen.open(context, inc.id), child: const Text('View')),
            TextButton(
              onPressed: () => showAssignSheet(context, inc.id),
              child: Text(inc.assignedResponderId == null ? 'Assign' : 'Reassign'),
            ),
            TextButton(
              onPressed: () => guarded(context, () => store.escalate(inc.id, reason: 'Escalated manually by command center'),
                  success: '${inc.id} escalated'),
              child: const Text('Escalate'),
            ),
            TextButton(
              onPressed: () => guarded(context, () => store.resolve(inc.id), success: '${inc.id} resolved'),
              child: const Text('Resolve'),
            ),
          ]),
        ),
      ),
    ]);
  }
}

// =============================================================== INCIDENTS

class AdminIncidents extends StatefulWidget {
  const AdminIncidents({super.key});
  @override
  State<AdminIncidents> createState() => _AdminIncidentsState();
}

class _AdminIncidentsState extends State<AdminIncidents> {
  String _filter = 'All';
  String _q = '';

  static const filters = [
    'All', 'Critical', 'High', 'Medium', 'Low', 'Reported', 'Assigned', 'En Route', 'On Scene', 'Resolved', 'Escalated',
  ];

  bool _match(Incident i, RescueStore s) {
    final ok = switch (_filter) {
      'Critical' => i.severityLevel == SeverityLevel.critical,
      'High' => i.severityLevel == SeverityLevel.high,
      'Medium' => i.severityLevel == SeverityLevel.medium,
      'Low' => i.severityLevel == SeverityLevel.low,
      'Reported' => i.status == IncidentStatus.reported,
      'Assigned' => i.status == IncidentStatus.assigned || i.status == IncidentStatus.accepted,
      'En Route' => i.status == IncidentStatus.enRoute,
      'On Scene' => i.status == IncidentStatus.onScene || i.status == IncidentStatus.arrived,
      'Resolved' => i.status == IncidentStatus.resolved,
      'Escalated' => i.escalated,
      _ => true,
    };
    if (!ok) return false;
    if (_q.isEmpty) return true;
    final q = _q.toLowerCase();
    final responder = s.responderById(i.assignedResponderId)?.name ?? '';
    return i.id.toLowerCase().contains(q) ||
        i.category.label.toLowerCase().contains(q) ||
        i.locationName.toLowerCase().contains(q) ||
        responder.toLowerCase().contains(q) ||
        i.reporterName.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RescueStore>();
    final list = store.incidents.where((i) => _match(i, store)).toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      TextField(
        decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search), hintText: 'Search ID, category, location, responder, student'),
        onChanged: (v) => setState(() => _q = v.trim()),
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: 40,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (final f in filters)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(label: Text(f), selected: _filter == f, onSelected: (_) => setState(() => _filter = f)),
            ),
        ]),
      ),
      SectionTitle('${list.length} incidents · archive included'),
      if (list.isEmpty) const EmptyState('No incidents match.'),
      for (final i in list) i.isActive ? _AdminIncidentCard(inc: i) : IncidentTile(i),
    ]);
  }
}

// =============================================================== RESPONDERS

class RespondersView extends StatelessWidget {
  const RespondersView({super.key});
  @override
  Widget build(BuildContext context) {
    final store = context.watch<RescueStore>();
    return ListView(padding: const EdgeInsets.all(16), children: [
      const SectionTitle('Responder roster'),
      for (final r in store.responders.values)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Panel(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(r.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(width: 8),
                Text(r.id, style: AppTheme.mono.copyWith(color: RgColors.muted, fontSize: 12)),
                const Spacer(),
                ResponderStatusPill(r.status, dense: true),
              ]),
              const SizedBox(height: 4),
              Text(r.type, style: const TextStyle(color: RgColors.muted)),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final s in r.skills) Pill(s.label, color: RgColors.blue, dense: true),
              ]),
              const SizedBox(height: 8),
              Text(
                'Workload: ${r.workload} · Current: ${r.currentIncidentId ?? '—'} · Resolved today: ${r.resolvedToday}\n'
                'Location (simulated): ${r.x.round()}, ${r.y.round()} m · Updated ${Fmt.time(r.lastUpdated)}',
                style: AppTheme.mono.copyWith(fontSize: 12, color: RgColors.muted),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => store.setDuty(r.id, r.status == ResponderStatus.offDuty),
                  child: Text(r.status == ResponderStatus.offDuty ? 'SET ON DUTY' : 'SET OFF DUTY'),
                ),
              ),
            ]),
          ),
        ),
    ]);
  }
}

// =============================================================== AUDIT TIMELINE

class AuditTimelineView extends StatefulWidget {
  const AuditTimelineView({super.key});
  @override
  State<AuditTimelineView> createState() => _AuditTimelineViewState();
}

class _AuditTimelineViewState extends State<AuditTimelineView> {
  String? _incident;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RescueStore>();
    final events = _incident == null ? store.allEvents.take(150).toList() : store.timeline(_incident!).toList();
    final ids = store.incidents.map((i) => i.id).toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('AUDIT TIMELINE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.6)),
      const Text('Every dispatch action is recorded with a timestamp and actor.',
          style: TextStyle(color: RgColors.muted, fontSize: 12.5)),
      const SizedBox(height: 10),
      SizedBox(
        height: 40,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(label: const Text('All incidents'), selected: _incident == null, onSelected: (_) => setState(() => _incident = null)),
          ),
          for (final id in ids)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(label: Text(id), selected: _incident == id, onSelected: (_) => setState(() => _incident = id)),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      Panel(child: TimelineView(events, showIncidentId: _incident == null)),
    ]);
  }
}
