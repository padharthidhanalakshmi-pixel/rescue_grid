import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/enums.dart';
import '../../services/incident_service.dart';
import '../../widgets/common.dart';
import '../../widgets/incident_tile.dart';
import '../incidents/incident_detail_screen.dart';
import '../notifications/notifications_screen.dart';
import 'report_screen.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({super.key});
  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _StudentHome(onReport: () => setState(() => _tab = 1)),
      ReportScreen(onSubmitted: (id) {
        setState(() => _tab = 0);
        IncidentDetailScreen.open(context, id);
      }),
      const _MyIncidents(),
      const NotificationsView(),
      const ProfileView(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(Brand.appName, style: TextStyle(fontWeight: FontWeight.w900)),
          Text(Brand.subtitle, style: TextStyle(fontSize: 11, color: RgColors.muted)),
        ]),
        actions: [
          const DemoModeBadge(),
          NotificationBell(onTap: () => setState(() => _tab = 3)),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(key: ValueKey(_tab), child: pages[_tab]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.sos_outlined), selectedIcon: Icon(Icons.sos), label: 'Report'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: 'Incidents'),
          NavigationDestination(
              icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Notifications'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _StudentHome extends StatelessWidget {
  const _StudentHome({required this.onReport});
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RescueStore>();
    final u = store.currentUser!;
    final mine = store.reportedBy(u.id);
    final active = mine.where((i) => i.isActive).toList();
    final recent = mine.where((i) => !i.isActive).take(3).toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('${Fmt.greeting(DateTime.now())}, ${u.name}',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
      const SizedBox(height: 2),
      const Text('LBRCE Campus', style: TextStyle(color: RgColors.muted)),
      const Text('Stay Safe • RescueGrid', style: TextStyle(color: RgColors.muted, fontSize: 12)),
      const SizedBox(height: 18),
      _SosCard(onTap: onReport),
      const SectionTitle('Active incident'),
      if (active.isEmpty)
        const Panel(child: Text('No active incident. You are all clear.', style: TextStyle(color: RgColors.muted))),
      for (final i in active) _ActiveTracking(incidentId: i.id),
      const SectionTitle('Recent incidents'),
      if (recent.isEmpty) const Panel(child: Text('No past reports.', style: TextStyle(color: RgColors.muted))),
      for (final i in recent) IncidentTile(i),
      const BrandFooter(),
    ]);
  }
}

class _SosCard extends StatelessWidget {
  const _SosCard({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE5303A), Color(0xFF7A0E16)],
        ),
        boxShadow: [BoxShadow(color: RgColors.red.withValues(alpha: 0.35), blurRadius: 30, offset: const Offset(0, 12))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('NEED HELP?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 4),
        const Text('Report an emergency immediately.', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: RgColors.redDeep,
              minimumSize: const Size.fromHeight(58),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: onTap,
            child: const Text('🚨  REPORT EMERGENCY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: 1)),
          ),
        ),
      ]),
    );
  }
}

class _ActiveTracking extends StatelessWidget {
  const _ActiveTracking({required this.incidentId});
  final String incidentId;
  @override
  Widget build(BuildContext context) {
    final store = context.watch<RescueStore>();
    final inc = store.incident(incidentId)!;
    final r = store.responderById(inc.assignedResponderId);
    final enRoute = inc.status == IncidentStatus.enRoute;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Panel(
        border: enRoute ? RgColors.blue : inc.severityLevel.color.withValues(alpha: 0.6),
        onTap: () => IncidentDetailScreen.open(context, inc.id),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('${inc.category.emoji}  ${inc.id}', style: AppTheme.mono.copyWith(fontWeight: FontWeight.w900)),
            const Spacer(),
            StatusPill(inc.status, dense: true),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            if (enRoute) const PulseDot(color: RgColors.blue, size: 7),
            Expanded(
              child: Text(
                switch (inc.status) {
                  IncidentStatus.reported => 'Finding the best responder…',
                  IncidentStatus.assigned => '${r?.name} assigned — waiting to accept',
                  IncidentStatus.accepted => '${r?.name} accepted your emergency',
                  IncidentStatus.enRoute => 'Responder is on the way.',
                  IncidentStatus.arrived => '${r?.name} has arrived.',
                  IncidentStatus.onScene => '${r?.name} is on scene.',
                  IncidentStatus.resolved => 'Resolved.',
                },
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ]),
          if (r != null && inc.status.index <= IncidentStatus.enRoute.index) ...[
            const SizedBox(height: 10),
            Text('${r.name}  ·  Distance: ${Fmt.distance(inc.distanceM)}  ·  ETA: ${Fmt.mmss(inc.etaSec)}',
                style: AppTheme.mono.copyWith(fontSize: 13)),
          ],
          const SizedBox(height: 8),
          SeverityBadge(inc.severityLevel, inc.severityScore, dense: true),
        ]),
      ),
    );
  }
}

class _MyIncidents extends StatelessWidget {
  const _MyIncidents();
  @override
  Widget build(BuildContext context) {
    final store = context.watch<RescueStore>();
    final mine = store.reportedBy(store.currentUser!.id);
    return ListView(padding: const EdgeInsets.all(16), children: [
      const SectionTitle('My reports'),
      if (mine.isEmpty) const EmptyState('You have not reported any incidents.'),
      for (final i in mine) IncidentTile(i),
    ]);
  }
}
