import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/routing/app_router.dart';
import 'services/incident_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase is optional. This build runs the in-memory DEMO MODE backend;
  // see README "Firebase Setup" for wiring a Firestore-backed store.
  runApp(
    ChangeNotifierProvider<RescueStore>(
      create: (_) => RescueStore(),
      child: const RescueGridApp(),
    ),
  );
}
