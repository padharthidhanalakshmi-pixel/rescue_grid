import 'dart:math' as math;

import '../models/dispatch.dart';
import '../models/enums.dart';
import '../models/incident.dart';
import '../models/responder.dart';

/// Ranks responders for an incident using skill match, distance/ETA,
/// availability and workload, with severity adjusting the ETA weight.
class DispatchService {
  /// Simulated campus response speed (brisk walk / campus vehicle), m/s.
  static const double speedMps = 2.0;
  static const int mobilizationSec = 30;

  static double distance(double x1, double y1, double x2, double y2) =>
      math.sqrt(math.pow(x1 - x2, 2) + math.pow(y1 - y2, 2));

  static int etaFor(double meters) => (meters / speedMps).round() + mobilizationSec;

  double skillMatch(Responder r, IncidentCategory c) {
    final primaryHits = c.primarySkills.where(r.skills.contains).length;
    if (primaryHits == c.primarySkills.length) return 0.95;
    if (primaryHits > 0) return 0.85;
    if (c.secondarySkills.any(r.skills.contains)) return 0.6;
    return 0.2;
  }

  double availabilityScore(ResponderStatus s) => switch (s) {
        ResponderStatus.available => 1.0,
        ResponderStatus.busy => 0.35,
        ResponderStatus.enRoute => 0.25,
        ResponderStatus.onScene => 0.15,
        ResponderStatus.offDuty => 0.0,
      };

  List<RankedResponder> rank({
    required Incident incident,
    required Iterable<Responder> responders,
    required DispatchWeights weights,
    Set<String> exclude = const {},
  }) {
    // Severity shifts emphasis toward speed of arrival.
    final etaBoost = switch (incident.severityLevel) {
      SeverityLevel.critical => 1.4,
      SeverityLevel.high => 1.2,
      _ => 1.0,
    };
    final wSkill = weights.skill.toDouble();
    final wEta = weights.eta * etaBoost;
    final wAvail = weights.availability.toDouble();
    final wLoad = weights.workload.toDouble();
    final wSum = math.max(1.0, wSkill + wEta + wAvail + wLoad);

    final out = <RankedResponder>[];
    for (final r in responders) {
      final d = distance(r.x, r.y, incident.x, incident.y);
      final eta = etaFor(d);
      final skill = skillMatch(r, incident.category);
      final avail = availabilityScore(r.status);
      final load = 1 - (math.min(r.workload, 4) / 4);
      final etaScore = 1 - (math.min(eta, 900) / 900);
      final total = (skill * wSkill + etaScore * wEta + avail * wAvail + load * wLoad) / wSum * 100;

      String? note;
      var eligible = true;
      if (r.status == ResponderStatus.offDuty) {
        eligible = false;
        note = 'Off duty';
      } else if (exclude.contains(r.id)) {
        eligible = false;
        note = 'Declined / no response';
      } else if (incident.assignedResponderId == r.id || incident.backupResponderIds.contains(r.id)) {
        eligible = false;
        note = 'Already on this incident';
      }
      out.add(RankedResponder(
        responder: r,
        skillMatch: skill,
        distanceM: d,
        etaSec: eta,
        availabilityScore: avail,
        workloadScore: load,
        total: total,
        eligible: eligible,
        note: note,
      ));
    }
    out.sort((a, b) {
      if (a.eligible != b.eligible) return a.eligible ? -1 : 1;
      return b.total.compareTo(a.total);
    });
    return out;
  }
}
