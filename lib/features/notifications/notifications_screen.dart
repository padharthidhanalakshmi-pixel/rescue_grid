import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../services/incident_service.dart';
import '../../widgets/common.dart';
import '../incidents/incident_detail_screen.dart';

/// In-app notification center (works in DEMO MODE without FCM).
class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RescueStore>();
    final items = store.notifications.forUser(store.currentUser);
    return ListView(padding: const EdgeInsets.all(16), children: [
      SectionTitle('Notifications',
          trailing: items.isEmpty
              ? null
              : TextButton(
                  onPressed: () => store.updateSettings(() {
                    for (final n in items) {
                      n.read = true;
                    }
                  }),
                  child: const Text('Mark all read'),
                )),
      if (items.isEmpty) const EmptyState('No notifications yet.', icon: Icons.notifications_none),
      for (final n in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Panel(
            border: n.read ? null : (n.critical ? RgColors.red : RgColors.blue),
            onTap: () {
              store.updateSettings(() => n.read = true);
              if (n.incidentId != null) IncidentDetailScreen.open(context, n.incidentId!);
            },
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(n.critical ? Icons.priority_high : Icons.notifications,
                  color: n.critical ? RgColors.red : RgColors.blue, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(n.title, style: TextStyle(fontWeight: n.read ? FontWeight.w600 : FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(n.body, style: const TextStyle(color: RgColors.muted, fontSize: 13)),
                ]),
              ),
              Text(Fmt.shortTime(n.timestamp), style: AppTheme.mono.copyWith(fontSize: 11, color: RgColors.muted)),
            ]),
          ),
        ),
    ]);
  }
}

class ProfileView extends StatelessWidget {
  const ProfileView({super.key, this.extra = const []});
  final List<Widget> extra;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RescueStore>();
    final u = store.currentUser;
    if (u == null) return const SizedBox.shrink();
    return ListView(padding: const EdgeInsets.all(16), children: [
      Panel(
        child: Row(children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: RgColors.blue.withValues(alpha: 0.2),
            child: Text(u.name.substring(0, 1), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(u.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              Text(u.email, style: const TextStyle(color: RgColors.muted)),
              const SizedBox(height: 6),
              Pill(u.role.name.toUpperCase(), color: RgColors.blue, dense: true),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (u.department != null) Text('Department: ${u.department}'),
          const SizedBox(height: 4),
          const Text('Campus: LBRCE, Mylavaram', style: TextStyle(color: RgColors.muted)),
        ]),
      ),
      ...extra,
      const SizedBox(height: 16),
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
        icon: const Icon(Icons.logout),
        label: const Text('SIGN OUT / SWITCH ROLE'),
        onPressed: store.logout,
      ),
      const BrandFooter(),
    ]);
  }
}

/// Bell icon with unread badge for app bars.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key, required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final store = context.watch<RescueStore>();
    final n = store.unreadFor(store.currentUser);
    return IconButton(
      onPressed: onTap,
      icon: Badge(isLabelVisible: n > 0, label: Text('$n'), child: const Icon(Icons.notifications_outlined)),
    );
  }
}
