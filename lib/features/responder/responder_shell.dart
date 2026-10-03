import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/enums.dart';
import '../../models/incident.dart';
import '../../models/responder.dart';
import '../../services/incident_service.dart';
import '../../widgets/common.dart';
import '../../widgets/incident_tile.dart';
import '../incidents/incident_detail_screen.dart';
import '../maps/campus_map.dart';
import '../notifications/notifications_screen.dart';

class ResponderShell extends StatefulWidget {
  const ResponderShell({super.key});
  @override
  State<ResponderShell> createState() => _ResponderShellState();
}

class _ResponderShellState extends State<ResponderShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RescueStore>();
    final me = store.responderForUser(store.currentUser!.id);
    if (me == null) return const Scaffold(body: EmptyState('No responder profile linked to this account.'));
    final pages = [
      _Dashboard(me: me),
      _Assignments(me: me),
      _MapTab(me: me),
      _History(me: me),
      const ProfileView(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('RescueGrid · Responder', style: TextStyle(fontWeight: FontWeight.w900)),
          Text(Brand.subtitle, style: TextStyle(fontSize: 11, color: RgColors.muted)),
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
        ],
      ),
      body: KeyedSubtree(key: ValueKey(_tab), child: pages[_tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: store.pendingFor(me.id).isNotEmpty,
              label: Text('${store.pendingFor(me.id).length}'),
              child: const Icon(Icons.assignment_outlined),
            ),
            label: 'Assignments',
          ),
          const NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Map'),
          const NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.me});
  final Responder me;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RescueStore>();
    final pending = store.pendingFor(me.id);
    final active = store.activeFor(me.id);
    final myResolved = store.historyFor(me.id);
    final times = myResolved.map((i) => i.responseTime).whereType<Duration>().toList();
    final avg = times.isEmpty ? null : Duration(seconds: times.fold<int>(0, (a, d) => a + d.inSeconds) ~/ times.length);

    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(Fmt.greeting(DateTime.now()).toUpperCase(),
          style: const TextStyle(color: RgColors.muted, letterSpacing: 1.6, fontSize: 12, fontWeight: FontWeight.w800)),
      Text(me.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
      Text(me.type, style: const TextStyle(color: RgColors.muted)),
      const SizedBox(height: 14),
      Panel(
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('STATUS', style: TextStyle(color: RgColors.muted, fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            ResponderStatusPill(me.status),
          ]),
          const Spacer(),
          const Text('On duty'),
          Switch(
            value: me.status != ResponderStatus.offDuty,
            onChanged: (v) => store.setDuty(me.id, v),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: StatCard(label: 'Active', value: '${pending.length + active.length}', color: RgColors.blue)),
        const SizedBox(width: 8),
        Expanded(child: StatCard(label: 'Resolved today', value: '${me.resolvedToday}', color: RgColors.green)),
        const SizedBox(width: 8),
        Expanded(child: StatCard(label: 'Avg response', value: Fmt.duration(avg))),
      ]),
      if (pending.isNotEmpty) ...[
        const SectionTitle('New assignment', trailing: PulseDot(size: 7)),
        for (final i in pending) AssignmentCard(inc: i),
      ],
      const SectionTitle('Active incidents'),
      if (active.isEmpty) const Panel(child: Text('No active incidents.', style: TextStyle(color: RgColors.muted))),
      for (final i in active) IncidentTile(i),
      const BrandFooter(),
    ]);
  }
}

/// Big assignment card with ACCEPT / DECLINE.
class AssignmentCard extends StatelessWidget {
  const AssignmentCard({super.key, required this.inc});
  final Incident inc;
  @override
  Widget build(BuildContext context) {
    final store = context.read<RescueStore>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Panel(
        border: RgColors.red,
        color: RgColors.red.withValues(alpha: 0.08),
        onTap: () => IncidentDetailScreen.open(context, inc.id),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${inc.category.emoji} ${inc.category.label.toUpperCase()}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('LBRCE Campus · ${inc.locationName}', style: const TextStyle(color: RgColors.muted)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _m('SEVERITY', '${inc.severityLevel.label} — ${inc.severityScore}', inc.severityLevel.color)),
            Expanded(child: _m('DISTANCE', Fmt.distance(inc.distanceM), RgColors.text)),
            Expanded(child: _m('ETA', Fmt.etaMinutes(inc.etaSec), RgColors.text)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: RgColors.red, minimumSize: const Size.fromHeight(50)),
                onPressed: () => showDeclineDialog(context, inc.id),
                child: const Text('DECLINE'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: RgColors.green, minimumSize: const Size.fromHeight(50)),
                onPressed: () {
                  store.accept(inc.id);
                  showMsg(context, 'Assignment accepted. Navigation enabled.');
                  IncidentDetailScreen.open(context, inc.id);
                },
                child: const Text('ACCEPT', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _m(String l, String v, Color c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l, style: const TextStyle(color: RgColors.muted, fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(v, style: AppTheme.mono.copyWith(fontWeight: FontWeight.w900, color: c, fontSize: 14.5)),
      ]);
}

class _Assignments extends StatelessWidget {
  const _Assignments({required this.me});
  final Responder me;
  @override
  Widget build(BuildContext context) {
    final store = context.watch<RescueStore>();
    final pending = store.pendingFor(me.id);
    final active = store.activeFor(me.id);
    return ListView(padding: const EdgeInsets.all(16), children: [
      const SectionTitle('Awaiting response'),
      if (pending.isEmpty) const Panel(child: Text('No pending assignments.', style: TextStyle(color: RgColors.muted))),
      for (final i in pending) AssignmentCard(inc: i),
      const SectionTitle('In progress'),
      if (active.isEmpty) const Panel(child: Text('Nothing in progress.', style: TextStyle(color: RgColors.muted))),
      for (final i in active) IncidentTile(i),
    ]);
  }
}

class _MapTab extends StatelessWidget {
  const _MapTab({required this.me});
  final Responder me;
  @override
  Widget build(BuildContext context) {
    final store = context.watch<RescueStore>();
    final mine = [...store.pendingFor(me.id), ...store.activeFor(me.id)];
    return ListView(padding: const EdgeInsets.all(16), children: [
      CampusMap(
        height: 440,
        focusIncidentId: mine.isEmpty ? null : mine.first.id,
        onIncidentTap: (id) => IncidentDetailScreen.open(context, id),
      ),
      const SizedBox(height: 10),
      Text('Your position (simulated): ${me.x.round()}, ${me.y.round()} m on the LBRCE demo grid',
          style: const TextStyle(color: RgColors.muted, fontSize: 12)),
    ]);
  }
}

class _History extends StatelessWidget {
  const _History({required this.me});
  final Responder me;
  @override
  Widget build(BuildContext context) {
    final store = context.watch<RescueStore>();
    final list = store.historyFor(me.id);
    return ListView(padding: const EdgeInsets.all(16), children: [
      const SectionTitle('Resolved incidents'),
      if (list.isEmpty) const EmptyState('No history yet.'),
      for (final i in list) IncidentTile(i),
    ]);
  }
}
