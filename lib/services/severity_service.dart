import '../models/campus_location.dart';
import '../models/enums.dart';
import '../models/severity.dart';

/// Transparent, rule-based severity engine (not machine learning).
///
/// score = category (max 40) + keywords (max 25) + people affected (max 15)
///       + time of day (max 10) + location risk (max 10)   → 0..100
class SeverityService {
  SeverityService({SeverityThresholds? thresholds}) : thresholds = thresholds ?? SeverityThresholds();

  SeverityThresholds thresholds;

  static const criticalKeywords = <String>[
    'unconscious', 'not breathing', 'bleeding', 'blood', 'fire', 'smoke', 'explosion',
    'weapon', 'knife', 'gun', 'collapsed', 'trapped', 'electrocuted', 'shock', 'burn',
    'chest pain', 'seizure', 'fainted', 'stabbed', 'gas leak',
  ];
  static const moderateKeywords = <String>[
    'injured', 'hurt', 'fight', 'spark', 'leak', 'dizzy', 'flood', 'smell', 'crowd',
    'broken', 'fracture', 'vomit', 'panic', 'short circuit', 'wire', 'water',
  ];

  SeverityResult assess({
    required IncidentCategory category,
    required String description,
    required int peopleAffected,
    required DateTime at,
    required CampusLocation location,
    int priorityBoost = 0,
  }) {
    final reasons = <String>[];
    final text = description.toLowerCase();

    final cat = category.baseScore;
    reasons.add('${category.label} (category weight $cat/40)');

    var kw = 0;
    final hits = <String>[];
    for (final k in criticalKeywords) {
      if (text.contains(k)) {
        kw += 18;
        hits.add(k);
      }
    }
    for (final k in moderateKeywords) {
      if (text.contains(k)) {
        kw += 8;
        hits.add(k);
      }
    }
    if (kw > 25) kw = 25;
    if (hits.isNotEmpty) reasons.add('Keywords detected: ${hits.map((h) => '“$h”').join(', ')}');

    final people = peopleAffected <= 1
        ? 3
        : peopleAffected == 2
            ? 7
            : peopleAffected == 3
                ? 10
                : peopleAffected == 4
                    ? 13
                    : 15;
    reasons.add(peopleAffected >= 5 ? '5+ people affected' : '$peopleAffected ${peopleAffected == 1 ? 'person' : 'people'} affected');

    final h = at.hour;
    final int time;
    final String timeReason;
    if (h >= 22 || h < 6) {
      time = 10;
      timeReason = 'Night hours — minimal staff on campus';
    } else if (h >= 18) {
      time = 7;
      timeReason = 'Evening — reduced staff on campus';
    } else if (h >= 9 && h < 17) {
      time = 5;
      timeReason = 'Class hours — high occupancy';
    } else {
      time = 3;
      timeReason = 'Off-peak daytime';
    }
    reasons.add(timeReason);

    final loc = location.risk < 0 ? 0 : (location.risk > 10 ? 10 : location.risk);
    if (loc >= 7) {
      reasons.add('High-risk location: ${location.name} ($loc/10)');
    } else {
      reasons.add('Location risk: ${location.name} ($loc/10)');
    }

    var score = cat + kw + people + time + loc + priorityBoost;
    if (score > 100) score = 100;
    if (score < 0) score = 0;
    if (priorityBoost > 0) reasons.add('Priority raised +$priorityBoost (backup requested)');

    final level = thresholds.levelFor(score);
    final action = switch (level) {
      SeverityLevel.critical => 'Immediate response required — alert all nearby units',
      SeverityLevel.high => 'Immediate response required',
      SeverityLevel.medium => 'Prompt response required',
      SeverityLevel.low => 'Routine response',
    };

    return SeverityResult(
      score: score,
      level: level,
      action: action,
      reasons: reasons,
      factors: [
        SeverityFactor('Category', cat, 40),
        SeverityFactor('Keywords', kw, 25),
        SeverityFactor('People affected', people, 15),
        SeverityFactor('Time of day', time, 10),
        SeverityFactor('Location risk', loc, 10),
        if (priorityBoost > 0) SeverityFactor('Priority boost', priorityBoost, 10),
      ],
    );
  }
}
