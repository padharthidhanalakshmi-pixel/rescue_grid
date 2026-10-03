import 'dart:async';

import '../models/campus_location.dart';
import '../models/enums.dart';
import '../models/incident.dart';
import 'incident_service.dart';

/// Drives the full RescueGrid story end-to-end for judges:
/// report → GPS → photo → severity → ranking → assignment → notification →
/// accept → route → ETA updates → arrival → backup → escalation → backup
/// assigned → resolved → timeline completed.
///
/// Every step calls the same store methods the real UI uses; nothing is faked
/// except GPS (simulated campus location) and the photo (demo placeholder).
class DemoOrchestrator {
  DemoOrchestrator(this.store);
  final RescueStore store;
  bool _cancelled = false;

  void cancel() => _cancelled = true;

  Future<void> _step(String text, [int ms = 1600]) async {
    if (_cancelled) throw _Cancelled();
    store.updateSettings(() => store.demoStep = text);
    await Future<void>.delayed(Duration(milliseconds: ms));
    if (_cancelled) throw _Cancelled();
  }

  Future<Incident?> run() async {
    if (store.demoRunning) return null;
    _cancelled = false;
    store.updateSettings(() {
      store.demoRunning = true;
      store.simulateMovement = true;
    });
    Incident? inc;
    try {
      final student = store.users['student01']!;
      final CampusLocation cse = store.locationById('cse') ?? store.locations.first;

      await _step('STEP 1 · Student 01 opens REPORT EMERGENCY');
      await _step('STEP 2 · Category: 🚑 Medical Emergency');
      await _step('STEP 3 · Location captured: CSE Department (simulated campus location)');
      await _step('STEP 4 · Photo attached (demo placeholder)');
      await _step('STEP 5 · “Student feeling unconscious near CSE Department” · 2 people');

      inc = store.reportIncident(
        reporter: student,
        category: IncidentCategory.medical,
        description: 'Student feeling unconscious near CSE Department',
        peopleAffected: 2,
        location: cse,
        demoPhoto: true,
      );
      final id = inc.id;
      await _step('STEP 6 · Severity Engine: ${inc.severityLevel.label} — ${inc.severityScore}/100', 2200);
      final top = inc.lastRanking.isEmpty ? null : inc.lastRanking.first;
      if (top != null) {
        await _step(
            'STEP 7 · Ranking: ${top.responder.name} · skill ${(top.skillMatch * 100).round()}% · ETA ${(top.etaSec / 60).ceil()} min',
            2200);
      }
      final assigned = store.responderById(inc.assignedResponderId);
      if (assigned == null) {
        await _step('No responders available — command center notified');
        return inc;
      }
      await _step('STEP 8 · Auto-assigned to ${assigned.name} · notification sent');
      await _step('STEP 9 · ${assigned.name} accepts the assignment');
      store.accept(id);
      await _step('STEP 10 · Navigation started · status EN ROUTE');
      store.startRoute(id);

      // Let live tracking run for a while so ETA visibly counts down.
      for (var i = 0; i < 4; i++) {
        final cur = store.incident(id)!;
        if (cur.status != IncidentStatus.enRoute) break;
        await _step('STEP 11 · Live tracking · ${cur.distanceM.round()} m · ETA ${_mmss(cur.etaSec)}', 1000);
      }

      await _step('STEP 12 · Responder requests BACKUP (crowd control)');
      store.requestBackup(id, ['Crowd control', 'Medical assistance']);
      final rec = store.incident(id)!.recommendedBackupId;
      await _step('STEP 13 · Command center receives escalation alert', 2000);
      if (rec != null) {
        store.assignBackup(id, rec);
        await _step('STEP 14 · Admin assigns backup: ${store.responderById(rec)?.name}');
      }

      // Wait for arrival (tracking) — force it if movement is slow.
      for (var i = 0; i < 20; i++) {
        final cur = store.incident(id)!;
        if (cur.status != IncidentStatus.enRoute) break;
        await _step('STEP 15 · En route · ${cur.distanceM.round()} m · ETA ${_mmss(cur.etaSec)}', 1000);
      }
      if (store.incident(id)!.status == IncidentStatus.enRoute) store.markArrived(id);
      await _step('STEP 16 · 📍 Responder ARRIVED');
      store.markOnScene(id);
      await _step('STEP 17 · Status ON SCENE — patient stabilised', 2200);
      store.resolve(id);
      await _step('STEP 18 · ✓ Incident RESOLVED · timeline completed & archived', 2600);
      return store.incident(id);
    } on _Cancelled {
      return inc;
    } finally {
      store.updateSettings(() {
        store.demoRunning = false;
        store.demoStep = null;
      });
    }
  }

  static String _mmss(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}

class _Cancelled implements Exception {}
