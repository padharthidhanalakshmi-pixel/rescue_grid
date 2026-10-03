import 'enums.dart';

class Responder {
  Responder({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.skills,
    required this.status,
    required this.x,
    required this.y,
    this.workload = 0,
    this.resolvedToday = 0,
    this.currentIncidentId,
  }) : lastUpdated = DateTime.now();

  final String id;
  final String userId;
  final String name;
  final String type;
  final List<Skill> skills;
  ResponderStatus status;
  double x;
  double y;
  int workload;
  int resolvedToday;
  String? currentIncidentId;
  DateTime lastUpdated;

  String get skillsLabel => skills.map((s) => s.label).join(' / ');
}
