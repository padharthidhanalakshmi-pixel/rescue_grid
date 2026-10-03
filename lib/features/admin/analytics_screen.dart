import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/enums.dart';
import '../../services/incident_service.dart';
import '../../widgets/common.dart';

class AnalyticsView extends StatelessWidget {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RescueStore>();
    final all = store.incidents;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final today = all.where((i) => !i.createdAt.isBefore(startOfDay)).length;
    final week = all.where((i) => now.difference(i.createdAt).inDays < 7).length;
    final resolved = all.where((i) => i.status == IncidentStatus.resolved).length;
    final critical = all.where((i) => i.severityLevel == SeverityLevel.critical).length;
    final rate = all.isEmpty ? 0 : (resolved / all.length * 100).round();

    final byCat = <String, double>{
      for (final c in IncidentCategory.values) '${c.emoji} ${c.label}': all.where((i) => i.category == c).length.toDouble(),
    }..removeWhere((_, v) => v == 0);
    final bySev = <String, double>{
      for (final s in SeverityLevel.values) s.label: all.where((i) => i.severityLevel == s).length.toDouble(),
    };
    final byLoc = <String, double>{};
    for (final i in all) {
      byLoc[i.locationName] = (byLoc[i.locationName] ?? 0) + 1;
    }
    final load = <String, double>{
      for (final r in store.responders.values) r.name: (r.workload + r.resolvedToday).toDouble(),
    };
    final trend = all.where((i) => i.responseTime != null).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('ANALYTICS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.6)),
      const Text('Seeded history + live session data (DEMO MODE).', style: TextStyle(color: RgColors.muted, fontSize: 12.5)),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (context, c) {
        return GridView.count(
          crossAxisCount: c.maxWidth > 700 ? 3 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.9,
          children: [
            StatCard(label: 'Incidents today', value: '$today'),
            StatCard(label: 'This week', value: '$week'),
            StatCard(label: 'Resolved', value: '$resolved', color: RgColors.green),
            StatCard(label: 'Critical', value: '$critical', color: RgColors.red),
            StatCard(label: 'Avg response', value: Fmt.duration(store.averageResponse), color: RgColors.blue),
            StatCard(label: 'Avg assignment', value: Fmt.duration(store.averageAssignment), color: RgColors.blue),
          ],
        );
      }),
      const SectionTitle('Resolution rate'),
      Panel(
        child: Row(children: [
          Text('$rate%', style: AppTheme.mono.copyWith(fontSize: 34, fontWeight: FontWeight.w900, color: RgColors.green)),
          const SizedBox(width: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                  value: rate / 100, minHeight: 14, backgroundColor: RgColors.panelHi, color: RgColors.green),
            ),
          ),
        ]),
      ),
      const SectionTitle('Incidents by category'),
      Panel(child: BarList(byCat, color: RgColors.red)),
      const SectionTitle('Incidents by severity'),
      Panel(
        child: BarList(bySev, colorFor: (k) => SeverityLevel.values.firstWhere((s) => s.label == k).color),
      ),
      const SectionTitle('Incidents by location'),
      Panel(child: BarList(byLoc, color: RgColors.blue)),
      const SectionTitle('Response time trend (minutes)'),
      Panel(
        child: trend.isEmpty
            ? const Text('No completed responses yet.')
            : SizedBox(
                height: 150,
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  for (final i in trend)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                          Text((i.responseTime!.inSeconds / 60).toStringAsFixed(1),
                              style: AppTheme.mono.copyWith(fontSize: 9, color: RgColors.muted)),
                          const SizedBox(height: 2),
                          Container(
                            height: (i.responseTime!.inSeconds / 60 / 10 * 110).clamp(4, 110).toDouble(),
                            decoration: BoxDecoration(color: RgColors.blue, borderRadius: BorderRadius.circular(4)),
                          ),
                        ]),
                      ),
                    ),
                ]),
              ),
      ),
      const SectionTitle('Responder workload (active + resolved today)'),
      Panel(child: BarList(load, color: RgColors.green)),
      const BrandFooter(),
    ]);
  }
}

/// Simple horizontal bar chart — no chart package dependency.
class BarList extends StatelessWidget {
  const BarList(this.data, {super.key, this.color = RgColors.blue, this.colorFor});
  final Map<String, double> data;
  final Color color;
  final Color Function(String key)? colorFor;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Text('No data', style: TextStyle(color: RgColors.muted));
    final max = data.values.fold<double>(0, (a, b) => b > a ? b : a);
    final entries = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Column(children: [
      for (final e in entries)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            SizedBox(
              width: 150,
              child: Text(e.key, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: max == 0 ? 0 : e.value / max,
                  minHeight: 12,
                  backgroundColor: RgColors.panelHi,
                  color: colorFor?.call(e.key) ?? color,
                ),
              ),
            ),
            SizedBox(width: 34, child: Text(e.value.round().toString(), textAlign: TextAlign.right, style: AppTheme.mono)),
          ]),
        ),
    ]);
  }
}
