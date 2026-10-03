import 'dart:async';

import '../models/app_user.dart';
import '../models/enums.dart';
import '../models/timeline_event.dart';

/// In-app notification center (works in DEMO MODE).
/// Firebase Cloud Messaging is NOT wired in this build; when configured, an FCM
/// handler should call [deliver] for incoming messages so the same UI is used.
class NotificationService {
  final List<AppNotification> items = [];
  final _stream = StreamController<AppNotification>.broadcast();
  int _seq = 0;
  bool bannersEnabled = true;

  Stream<AppNotification> get stream => _stream.stream;

  AppNotification deliver({
    required String title,
    required String body,
    String? toUser,
    UserRole? toRole,
    String? incidentId,
    bool critical = false,
  }) {
    final n = AppNotification(
      id: 'N${++_seq}',
      title: title,
      body: body,
      timestamp: DateTime.now(),
      targetUserId: toUser,
      targetRole: toRole,
      incidentId: incidentId,
      critical: critical,
    );
    items.insert(0, n);
    _stream.add(n);
    return n;
  }

  static bool isFor(AppNotification n, AppUser? u) {
    if (u == null) return false;
    if (n.targetUserId != null) return n.targetUserId == u.id;
    if (n.targetRole != null) return n.targetRole == u.role;
    return true;
  }

  List<AppNotification> forUser(AppUser? u) => items.where((n) => isFor(n, u)).toList();

  void clear() => items.clear();

  void dispose() => _stream.close();
}
