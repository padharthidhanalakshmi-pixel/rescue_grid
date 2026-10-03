import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

enum UserRole { student, responder, admin }

extension UserRoleX on UserRole {
  String get label => switch (this) {
        UserRole.student => 'Student',
        UserRole.responder => 'Responder',
        UserRole.admin => 'Administrator',
      };
}

enum Skill { medical, firstAid, fireSafety, security, electrical, disasterResponse }

extension SkillX on Skill {
  String get label => switch (this) {
        Skill.medical => 'Medical',
        Skill.firstAid => 'First Aid',
        Skill.fireSafety => 'Fire Safety',
        Skill.security => 'Security',
        Skill.electrical => 'Electrical',
        Skill.disasterResponse => 'Disaster Response',
      };
}

enum IncidentCategory { fire, medical, security, electrical, accident, flooding, chemical, other }

extension IncidentCategoryX on IncidentCategory {
  String get label => switch (this) {
        IncidentCategory.fire => 'Fire',
        IncidentCategory.medical => 'Medical Emergency',
        IncidentCategory.security => 'Security Threat',
        IncidentCategory.electrical => 'Electrical Hazard',
        IncidentCategory.accident => 'Accident',
        IncidentCategory.flooding => 'Water/Flooding',
        IncidentCategory.chemical => 'Chemical Hazard',
        IncidentCategory.other => 'Other Emergency',
      };

  String get emoji => switch (this) {
        IncidentCategory.fire => '🔥',
        IncidentCategory.medical => '🚑',
        IncidentCategory.security => '🛡',
        IncidentCategory.electrical => '⚡',
        IncidentCategory.accident => '🚨',
        IncidentCategory.flooding => '💧',
        IncidentCategory.chemical => '🧪',
        IncidentCategory.other => '🆘',
      };

  /// Category weight in the severity engine (max 40).
  int get baseScore => switch (this) {
        IncidentCategory.fire => 40,
        IncidentCategory.medical => 40,
        IncidentCategory.chemical => 38,
        IncidentCategory.security => 35,
        IncidentCategory.electrical => 32,
        IncidentCategory.accident => 32,
        IncidentCategory.flooding => 22,
        IncidentCategory.other => 15,
      };

  List<Skill> get primarySkills => switch (this) {
        IncidentCategory.fire => [Skill.fireSafety],
        IncidentCategory.medical => [Skill.medical, Skill.firstAid],
        IncidentCategory.security => [Skill.security],
        IncidentCategory.electrical => [Skill.electrical],
        IncidentCategory.accident => [Skill.firstAid, Skill.medical],
        IncidentCategory.flooding => [Skill.disasterResponse],
        IncidentCategory.chemical => [Skill.fireSafety, Skill.disasterResponse],
        IncidentCategory.other => [Skill.disasterResponse],
      };

  List<Skill> get secondarySkills => switch (this) {
        IncidentCategory.fire => [Skill.disasterResponse],
        IncidentCategory.medical => [Skill.disasterResponse],
        IncidentCategory.security => [Skill.disasterResponse],
        IncidentCategory.electrical => [Skill.fireSafety],
        IncidentCategory.accident => [Skill.security, Skill.disasterResponse],
        IncidentCategory.flooding => [Skill.electrical],
        IncidentCategory.chemical => [Skill.medical],
        IncidentCategory.other => [Skill.security, Skill.firstAid],
      };
}

enum SeverityLevel { low, medium, high, critical }

extension SeverityLevelX on SeverityLevel {
  String get label => name.toUpperCase();

  Color get color => switch (this) {
        SeverityLevel.low => RgColors.green,
        SeverityLevel.medium => RgColors.yellow,
        SeverityLevel.high => RgColors.orange,
        SeverityLevel.critical => RgColors.red,
      };
}

enum IncidentStatus { reported, assigned, accepted, enRoute, arrived, onScene, resolved }

extension IncidentStatusX on IncidentStatus {
  String get label => switch (this) {
        IncidentStatus.reported => 'REPORTED',
        IncidentStatus.assigned => 'ASSIGNED',
        IncidentStatus.accepted => 'ACCEPTED',
        IncidentStatus.enRoute => 'EN ROUTE',
        IncidentStatus.arrived => 'ARRIVED',
        IncidentStatus.onScene => 'ON SCENE',
        IncidentStatus.resolved => 'RESOLVED',
      };

  Color get color => switch (this) {
        IncidentStatus.reported => RgColors.red,
        IncidentStatus.assigned => RgColors.amber,
        IncidentStatus.accepted => RgColors.blue,
        IncidentStatus.enRoute => RgColors.blue,
        IncidentStatus.arrived => RgColors.green,
        IncidentStatus.onScene => RgColors.green,
        IncidentStatus.resolved => RgColors.muted,
      };

  bool get isActive => this != IncidentStatus.resolved;
}

enum ResponderStatus { offDuty, available, enRoute, onScene, busy }

extension ResponderStatusX on ResponderStatus {
  String get label => switch (this) {
        ResponderStatus.offDuty => 'OFF DUTY',
        ResponderStatus.available => 'AVAILABLE',
        ResponderStatus.enRoute => 'EN ROUTE',
        ResponderStatus.onScene => 'ON SCENE',
        ResponderStatus.busy => 'BUSY',
      };

  Color get color => switch (this) {
        ResponderStatus.offDuty => RgColors.muted,
        ResponderStatus.available => RgColors.green,
        ResponderStatus.enRoute => RgColors.blue,
        ResponderStatus.onScene => RgColors.amber,
        ResponderStatus.busy => RgColors.orange,
      };
}

enum TimelineType {
  reported,
  gps,
  photo,
  severity,
  ranking,
  assigned,
  notified,
  accepted,
  declined,
  escalated,
  enRoute,
  arrived,
  onScene,
  backupRequested,
  backupAssigned,
  backupArrived,
  priority,
  resolved,
  archived,
  note,
}

extension TimelineTypeX on TimelineType {
  IconData get icon => switch (this) {
        TimelineType.reported => Icons.campaign,
        TimelineType.gps => Icons.my_location,
        TimelineType.photo => Icons.photo_camera,
        TimelineType.severity => Icons.speed,
        TimelineType.ranking => Icons.leaderboard,
        TimelineType.assigned => Icons.assignment_ind,
        TimelineType.notified => Icons.notifications_active,
        TimelineType.accepted => Icons.check_circle,
        TimelineType.declined => Icons.cancel,
        TimelineType.escalated => Icons.warning_amber,
        TimelineType.enRoute => Icons.directions_run,
        TimelineType.arrived => Icons.place,
        TimelineType.onScene => Icons.health_and_safety,
        TimelineType.backupRequested => Icons.group_add,
        TimelineType.backupAssigned => Icons.groups,
        TimelineType.backupArrived => Icons.how_to_reg,
        TimelineType.priority => Icons.trending_up,
        TimelineType.resolved => Icons.verified,
        TimelineType.archived => Icons.inventory_2,
        TimelineType.note => Icons.notes,
      };

  Color get color => switch (this) {
        TimelineType.reported => RgColors.red,
        TimelineType.declined => RgColors.red,
        TimelineType.escalated => RgColors.amber,
        TimelineType.backupRequested => RgColors.amber,
        TimelineType.priority => RgColors.amber,
        TimelineType.resolved => RgColors.green,
        TimelineType.accepted => RgColors.green,
        TimelineType.arrived => RgColors.green,
        TimelineType.archived => RgColors.muted,
        _ => RgColors.blue,
      };
}
