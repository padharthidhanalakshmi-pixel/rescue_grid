import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/admin/admin_shell.dart';
import '../../features/auth/login_screen.dart';
import '../../features/responder/responder_shell.dart';
import '../../features/student/student_shell.dart';
import '../../models/enums.dart';
import '../../models/timeline_event.dart';
import '../../services/incident_service.dart';
import '../../services/notification_service.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

final messengerKey = GlobalKey<ScaffoldMessengerState>();

class RescueGridApp extends StatelessWidget {
  const RescueGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Brand.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      scaffoldMessengerKey: messengerKey,
      home: const _NotificationBridge(child: RoleGate()),
    );
  }
}

/// Role-based routing: each role only ever sees its own shell.
class RoleGate extends StatelessWidget {
  const RoleGate({super.key});
  @override
  Widget build(BuildContext context) {
    final user = context.select<RescueStore, String?>((s) => s.currentUser?.id);
    final role = context.read<RescueStore>().currentUser?.role;
    final Widget page = switch (role) {
      null => const LoginScreen(),
      UserRole.student => const StudentShell(),
      UserRole.responder => const ResponderShell(),
      UserRole.admin => const AdminShell(),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: KeyedSubtree(key: ValueKey(user ?? 'login'), child: page),
    );
  }
}

/// Shows in-app banners for notifications addressed to the signed-in user.
class _NotificationBridge extends StatefulWidget {
  const _NotificationBridge({required this.child});
  final Widget child;
  @override
  State<_NotificationBridge> createState() => _NotificationBridgeState();
}

class _NotificationBridgeState extends State<_NotificationBridge> {
  StreamSubscription<AppNotification>? _sub;

  @override
  void initState() {
    super.initState();
    final store = context.read<RescueStore>();
    _sub = store.notifications.stream.listen((n) {
      if (!store.notifications.bannersEnabled) return;
      if (!NotificationService.isFor(n, store.currentUser)) return;
      messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          duration: const Duration(seconds: 3),
          backgroundColor: n.critical ? RgColors.redDeep : RgColors.panelHi,
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(n.title, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 2),
            Text(n.body, style: const TextStyle(color: Colors.white70)),
          ]),
        ));
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
