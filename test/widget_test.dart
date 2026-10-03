import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rescuegrid/core/routing/app_router.dart';
import 'package:rescuegrid/services/incident_service.dart';

void main() {
  testWidgets('Login screen shows LBRCE branding and logs in a demo admin', (tester) async {
    final store = RescueStore(startTicker: false)..escalationTimeoutSec = 0;
    await tester.pumpWidget(
      ChangeNotifierProvider<RescueStore>.value(value: store, child: const RescueGridApp()),
    );
    expect(find.text('🚨 RescueGrid'), findsOneWidget);
    expect(find.text('Lakireddy Bali Reddy College of Engineering'), findsOneWidget);

    store.login('admin@rescuegrid.demo', 'Admin@123');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('RESCUEGRID'), findsOneWidget);
    expect(find.text('LBRCE COMMAND CENTER'), findsOneWidget);

    // Unmount before disposing the store so no listeners remain.
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });
}
