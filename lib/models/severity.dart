import 'enums.dart';

class SeverityFactor {
  const SeverityFactor(this.label, this.points, this.max);
  final String label;
  final int points;
  final int max;
}

class SeverityResult {
  const SeverityResult({
    required this.score,
    required this.level,
    required this.factors,
    required this.reasons,
    required this.action,
  });
  final int score;
  final SeverityLevel level;
  final List<SeverityFactor> factors;
  final List<String> reasons;
  final String action;
}

class SeverityThresholds {
  SeverityThresholds({this.mediumMin = 31, this.highMin = 61, this.criticalMin = 81});
  int mediumMin;
  int highMin;
  int criticalMin;

  SeverityLevel levelFor(int score) {
    if (score >= criticalMin) return SeverityLevel.critical;
    if (score >= highMin) return SeverityLevel.high;
    if (score >= mediumMin) return SeverityLevel.medium;
    return SeverityLevel.low;
  }
}
