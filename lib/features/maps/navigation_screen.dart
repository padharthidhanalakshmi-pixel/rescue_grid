import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/enums.dart';
import '../../models/incident.dart';
import '../../services/incident_service.dart';
import '../../widgets/common.dart';
import 'campus_map.dart';

/// Opens turn-by-turn navigation in Google Maps when the incident has real
/// device GPS; otherwise returns false so the caller shows the simulated route.
Future<bool> openExternalNavigation(Incident inc) async {
  final g = inc.gps;
  if (g == null || !g.isReal) return false;
  final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${g.latitude},${g.longitude}&travelmode=walking');
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

class NavigationScreen extends StatelessWidget {
  const NavigationScreen({super.key, required this.incidentId});
  final String incidentId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RescueStore>();
    final inc = store.incident(incidentId);
    if (inc == null) return const Scaffold(body: EmptyState('Incident not found'));
    final hasGps = inc.gps?.isReal ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('NAVIGATION'), actions: const [DemoModeBadge()]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('INCIDENT LOCATION', style: TextStyle(color: RgColors.muted, letterSpacing: 1.4, fontSize: 11, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('LBRCE Campus · ${inc.locationName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _big('DISTANCE', Fmt.distance(inc.distanceM))),
              Expanded(child: _big('ETA', Fmt.mmss(inc.etaSec))),
              Expanded(child: _big('STATUS', inc.status.label, color: inc.status.color, size: 16)),
            ]),
          ]),
        ),
        const SizedBox(height: 14),
        CampusMap(focusIncidentId: inc.id, height: 340),
        const SizedBox(height: 8),
        Text(
          hasGps
              ? 'Reporter GPS available — OPEN NAVIGATION launches Google Maps.'
              : 'No real GPS on this report — route shown is SIMULATED on the LBRCE demo map.',
          style: const TextStyle(color: RgColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.navigation),
              label: const Text('OPEN NAVIGATION'),
              onPressed: () async {
                final ok = await openExternalNavigation(inc);
                if (!ok && context.mounted) {
                  showMsg(context, 'External maps unavailable — using simulated LBRCE route.');
                }
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              icon: const Icon(Icons.directions_run),
              label: const Text('START ROUTE'),
              onPressed: inc.status == IncidentStatus.accepted ? () => store.startRoute(inc.id) : null,
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _big(String label, String value, {Color color = RgColors.text, double size = 24}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: RgColors.muted, fontSize: 10.5, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(value, style: AppTheme.mono.copyWith(fontSize: size, fontWeight: FontWeight.w900, color: color)),
      ]);
}
