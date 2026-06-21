import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers.dart';
import 'core/secure/secure_store.dart';
import 'features/printing/application/providers.dart';
import 'features/sync/application/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // Read (or create on first run) the database encryption key from OS-encrypted
  // secure storage before the provider graph opens the database.
  final dbKey = await SecureStore().getOrCreateDbKey();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      dbKeyProvider.overrideWithValue(dbKey),
    ],
  );
  // Resume any print jobs interrupted by the last shutdown.
  await container.read(printServiceProvider).start();
  // Best-effort cloud sync on launch (no-op when not configured); never
  // blocks startup and failures are surfaced in Settings, not here.
  unawaited(container.read(syncServiceProvider).syncNow());
  runApp(
    UncontrolledProviderScope(container: container, child: const MerchantApp()),
  );
}
