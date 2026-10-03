import 'campus_location.dart';
import 'dispatch.dart';
import 'enums.dart';
import 'severity.dart';

class Incident {
  Incident({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.category,
    required this.description,
    required this.locationId,
    required this.locationName,
    required this.x,
    required this.y,
    required this.peopleAffected,
    required this.severity,
    required this.createdAt,
    this.gps,
    this.photoPath,
    this.demoPhoto = false,
    this.isSeed = false,
  }) : status = IncidentStatus.reported;

  final String id;
  final String reporterId;
  final String reporterName;
  final IncidentCategory category;
  final String description;
  final String locationId;
  final String locationName;
  final double x;
  final double y;
  final int peopleAffected;
  final DateTime createdAt;
  final GeoReading? gps;
  final String? photoPath;
  final bool demoPhoto;
  final bool isSeed;

  SeverityResult severity;
  IncidentStatus status;
  String? assignedResponderId;
  final List<String> backupResponderIds = [];
  String? recommendedBackupId;
  final Set<String> declinedBy = {};
  List<RankedResponder> lastRanking = const [];

  DateTime? assignedAt;
  DateTime? acceptedAt;
  DateTime? arrivedAt;
  DateTime? resolvedAt;

  bool escalated = false;
  bool backupRequested = false;
  List<String> backupReasons = const [];

  /// Live tracking values (updated by the tracking ticker).
  double distanceM = 0;
  int etaSec = 0;
  bool trackingActive = false;

  int get severityScore => severity.score;
  SeverityLevel get severityLevel => severity.level;
  bool get isActive => status.isActive;

  Duration? get responseTime => arrivedAt?.difference(createdAt);
  Duration? get assignmentTime => assignedAt?.difference(createdAt);
  Duration? get resolutionTime => resolvedAt?.difference(createdAt);
  String? get photoUrl => photoPath;
}
