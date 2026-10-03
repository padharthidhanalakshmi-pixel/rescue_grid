import 'enums.dart';

class TimelineEvent {
  const TimelineEvent({
    required this.id,
    required this.incidentId,
    required this.type,
    required this.message,
    required this.timestamp,
    this.actorId,
  });
  final String id;
  final String incidentId;
  final TimelineType type;
  final String message;
  final DateTime timestamp;
  final String? actorId;
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.targetUserId,
    this.targetRole,
    this.incidentId,
    this.critical = false,
  });
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final String? targetUserId;
  final UserRole? targetRole;
  final String? incidentId;
  final bool critical;
  bool read = false;
}
