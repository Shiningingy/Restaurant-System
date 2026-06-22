import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers.dart';
import 'core/secure/secure_store.dart';
import 'features/customer_display/presentation/customer_display_app.dart';
import 'features/printing/application/providers.dart';
import 'features/sync/application/providers.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  // desktop_multi_window starts a sub-window with the Dart entrypoint arguments
  // ["multi_window", windowId, argumentJson]. That's the deterministic signal
  // that this engine is the customer display (more reliable than
  // fromCurrentEngine, which can race during window creation). The display owns
  // no database/cloud — it just renders what the POS window pushes it over the
  // customer-display channel.
  if (args.isNotEmpty && args.first == 'multi_window') {
    final argStr = args.length > 2 ? args[2] : '';
    runApp(
      CustomerDisplayApp(
        args: argStr.isEmpty
            ? const <String, dynamic>{}
            : jsonDecode(argStr) as Map<String, dynamic>,
      ),
    );
    return;
  }
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
  // Load the cloud refresh token from secure storage (migrating any token left
  // in shared_preferences by an older build) before sync reads it.
  await container.read(syncSettingsProvider).warmRefreshToken();
  // Resume any print jobs interrupted by the last shutdown.
  await container.read(printServiceProvider).start();
  // Best-effort cloud sync on launch (no-op when not configured); never
  // blocks startup and failures are surfaced in Settings, not here.
  unawaited(container.read(syncServiceProvider).syncNow());
  runApp(
    UncontrolledProviderScope(container: container, child: const MerchantApp()),
  );
}
