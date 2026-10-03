import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/enums.dart';
import '../../services/incident_service.dart';
import '../../widgets/common.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RescueStore>();
    final w = store.weights;
    final t = store.severity.thresholds;

    Widget slider(String label, int value, int min, int max, void Function(int) set, {String suffix = '%'}) {
      if (max <= min) return Text('$label: $value$suffix', style: AppTheme.mono);
      return Row(children: [
          SizedBox(width: 130, child: Text(label)),
          Expanded(
            child: Slider(
              value: value.clamp(min, max).toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: max - min,
              label: '$value$suffix',
              onChanged: (v) => store.updateSettings(() => set(v.round())),
            ),
          ),
          SizedBox(width: 52, child: Text('$value$suffix', textAlign: TextAlign.right, style: AppTheme.mono)),
        ]);
    }

    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('SETTINGS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.6)),
      Text(Brand.adminTitle, style: const TextStyle(color: RgColors.muted, fontSize: 12.5)),
      const SectionTitle('Demo mode'),
      Panel(
        child: Column(children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Demo Mode'),
            subtitle: const Text('In-memory backend, seeded accounts, demo controls. Firebase is not configured in this build.'),
            value: store.demoMode,
            onChanged: (v) => store.updateSettings(() => store.demoMode = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Simulate responder movement'),
            subtitle: const Text('Moves en-route responders on the LBRCE demo map'),
            value: store.simulateMovement,
            onChanged: (v) => store.updateSettings(() => store.simulateMovement = v),
          ),
          slider('Sim speed', store.simulationSpeed.round(), 1, 10, (v) => store.simulationSpeed = v.toDouble(), suffix: 'x'),
        ]),
      ),
      const SectionTitle('Notification settings'),
      Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('In-app alert banners'),
            value: store.notifications.bannersEnabled,
            onChanged: (v) => store.updateSettings(() => store.notifications.bannersEnabled = v),
          ),
          const Text('Push (FCM): not configured — see README. In-app notification center is active.',
              style: TextStyle(color: RgColors.muted, fontSize: 12)),
        ]),
      ),
      const SectionTitle('Escalation'),
      Panel(
        child: slider('Accept timeout', store.escalationTimeoutSec, 10, 180, (v) => store.escalationTimeoutSec = v, suffix: 's'),
      ),
      const SectionTitle('Dispatch weights'),
      Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          slider('Skill match', w.skill, 0, 100, (v) => w.skill = v),
          slider('Distance / ETA', w.eta, 0, 100, (v) => w.eta = v),
          slider('Availability', w.availability, 0, 100, (v) => w.availability = v),
          slider('Workload', w.workload, 0, 100, (v) => w.workload = v),
          Text('Total ${w.total}% (weights are normalised automatically). Critical incidents boost ETA weight ×1.4, high ×1.2.',
              style: TextStyle(color: w.total == 100 ? RgColors.muted : RgColors.amber, fontSize: 12)),
          TextButton(
            onPressed: () => store.updateSettings(() {
              w.skill = 40;
              w.eta = 25;
              w.availability = 20;
              w.workload = 15;
            }),
            child: const Text('Reset to 40 / 25 / 20 / 15'),
          ),
        ]),
      ),
      const SectionTitle('Severity thresholds'),
      Panel(
        child: Column(children: [
          slider('MEDIUM from', t.mediumMin, 1, t.highMin - 1, (v) => t.mediumMin = v, suffix: ''),
          slider('HIGH from', t.highMin, t.mediumMin + 1, t.criticalMin - 1, (v) => t.highMin = v, suffix: ''),
          slider('CRITICAL from', t.criticalMin, t.highMin + 1, 100, (v) => t.criticalMin = v, suffix: ''),
          const Text('Applies to new incidents.', style: TextStyle(color: RgColors.muted, fontSize: 12)),
        ]),
      ),
      const SectionTitle('Incident categories'),
      Panel(
        child: Wrap(spacing: 6, runSpacing: 6, children: [
          for (final c in IncidentCategory.values) Pill('${c.emoji} ${c.label} · ${c.baseScore}', color: RgColors.red, dense: true),
        ]),
      ),
      const SectionTitle('Responder skills'),
      Panel(
        child: Wrap(spacing: 6, runSpacing: 6, children: [
          for (final s in Skill.values) Pill(s.label, color: RgColors.blue, dense: true),
        ]),
      ),
      SectionTitle('Campus locations',
          trailing: TextButton.icon(
              onPressed: () => _addLocation(context), icon: const Icon(Icons.add), label: const Text('Add'))),
      const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text(
          'All positions are SIMULATED on a schematic grid. Names marked ✓ appear in public LBRCE material; '
          'others are DEMO LOCATION names — edit to match the real campus.',
          style: TextStyle(color: RgColors.muted, fontSize: 12),
        ),
      ),
      for (final l in store.locations)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Panel(
            padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
            child: Row(children: [
              Expanded(child: Text('${l.verifiedName ? '✓ ' : ''}${l.name}')),
              Text('risk ${l.risk}', style: AppTheme.mono.copyWith(color: RgColors.muted)),
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: l.risk > 0 ? () => store.updateSettings(() => l.risk -= 1) : null,
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: l.risk < 10 ? () => store.updateSettings(() => l.risk += 1) : null,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => store.removeLocation(l.id),
              ),
            ]),
          ),
        ),
      const SectionTitle('Danger zone'),
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(foregroundColor: RgColors.red),
        onPressed: () {
          store.resetDemo();
          showMsg(context, 'Demo data reset.');
        },
        icon: const Icon(Icons.restart_alt),
        label: const Text('RESET DEMO DATA'),
      ),
      const BrandFooter(),
    ]);
  }

  Future<void> _addLocation(BuildContext context) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add campus location'),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(hintText: 'Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('ADD')),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty || !context.mounted) return;
    context.read<RescueStore>().addLocation(name, 5);
  }
}
